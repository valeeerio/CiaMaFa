import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../places/place_candidate.dart';
import 'activity.dart';
import 'plan.dart';

/// Nome del luogo nel piano quando non c'è una via né un nome.
const unnamedPlaceName = 'Punto sulla mappa';

/// Esito di un lancio (vedi `launch_plan`).
sealed class LaunchResult {
  const LaunchResult();
}

/// Piano creato.
final class Launched extends LaunchResult {
  const Launched({required this.planId, required this.placeName});

  final String planId;
  final String placeName;
}

/// Un amico ha già proposto questo posto per questa attività oggi.
final class DuplicatePlan extends LaunchResult {
  const DuplicatePlan(this.planId);

  final String planId;
}

/// Hai già piani attivi oggi: serve conferma per lanciarne un altro.
final class NeedsConfirmation extends LaunchResult {
  const NeedsConfirmation(this.activeCount);

  final int activeCount;
}

/// Una notifica in-app (banner): nuovo piano di un amico o voto sul tuo piano.
class PlanAnnouncement {
  const PlanAnnouncement({
    required this.planId,
    required this.title,
    required this.subtitle,
    this.cancelled = false,
  });

  final String planId;
  final String title;
  final String subtitle;

  /// Piano annullato: non esiste più, il tocco porta alla lista.
  final bool cancelled;
}

abstract interface class PlansRepository {
  /// Lancia il piano per [activity] in [place]. Se hai già piani attivi oggi
  /// serve [confirmExtra] (altrimenti [NeedsConfirmation]).
  Future<LaunchResult> launch({
    required Activity activity,
    required PlaceCandidate place,
    bool confirmExtra = false,
  });

  /// Piani di oggi con i loro voti (la RLS nasconde quelli scaduti).
  Future<List<Plan>> todaysPlans();

  /// Elimina un tuo piano (prima della scadenza). Lancia se non è stato
  /// eliminato (non è tuo o non c'è più).
  Future<void> deletePlan(String planId);

  /// Imposta il tuo voto su [planId]; `null` lo toglie.
  Future<void> setVote({
    required String planId,
    required String profileId,
    required VoteChoice? choice,
  });

  /// Emette a ogni cambiamento di piani o voti (Realtime, app aperta).
  Stream<void> changes();

  /// Notifiche in tempo reale per [selfId]: nuovi piani degli ALTRI e voti degli
  /// altri sui TUOI piani.
  Stream<PlanAnnouncement> announcements({required String selfId});
}

/// Nome del luogo come finisce nel piano: "La tua posizione" senza via non dice
/// nulla agli amici.
String placeNameForPlan(PlaceCandidate place) =>
    place.isUserPosition && place.street == null
    ? unnamedPlaceName
    : place.name;

class SupabasePlansRepository implements PlansRepository {
  SupabasePlansRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<LaunchResult> launch({
    required Activity activity,
    required PlaceCandidate place,
    bool confirmExtra = false,
  }) async {
    final json = await _client.rpc<Map<String, dynamic>>(
      'launch_plan',
      params: {
        'p_activity_id': activity.id,
        'p_name': placeNameForPlan(place),
        'p_lat': place.lat,
        'p_lng': place.lng,
        'p_address': place.address,
        'p_external_source': place.externalSource,
        'p_external_id': place.externalId,
        'p_confirm_extra': confirmExtra,
      },
    );
    return parseLaunchResult(json);
  }

  static LaunchResult parseLaunchResult(Map<String, dynamic> json) =>
      switch (json['status']) {
        'launched' => Launched(
          planId: json['plan_id'] as String,
          placeName: json['place_name'] as String,
        ),
        'duplicate' => DuplicatePlan(json['plan_id'] as String),
        'needs_confirmation' => NeedsConfirmation(
          (json['active_count'] as num).toInt(),
        ),
        final other => throw FormatException('Esito sconosciuto: $other'),
      };

  static const _planSelect =
      'id, activity_id, emoji, label, creator_id, created_at, '
      'profiles!plans_creator_id_fkey(nickname), '
      'places(name, address, lat, lng), '
      'votes(profile_id, vote, profiles(nickname))';

  @override
  Future<List<Plan>> todaysPlans() async {
    final rows = await _client
        .from('plans')
        .select(_planSelect)
        .order('created_at', ascending: false);
    return sortPlans([for (final r in rows) Plan.fromRow(r)]);
  }

  @override
  Future<void> deletePlan(String planId) async {
    // La RLS lascia eliminare solo i propri piani: senza righe restituite non
    // è stato eliminato nulla.
    final deleted = await _client
        .from('plans')
        .delete()
        .eq('id', planId)
        .select('id');
    if (deleted.isEmpty) throw StateError('Piano non eliminato');
  }

  @override
  Future<void> setVote({
    required String planId,
    required String profileId,
    required VoteChoice? choice,
  }) async {
    if (choice == null) {
      await _client
          .from('votes')
          .delete()
          .eq('plan_id', planId)
          .eq('profile_id', profileId);
    } else {
      await _client.from('votes').upsert({
        'plan_id': planId,
        'profile_id': profileId,
        'vote': choice.name,
      }, onConflict: 'plan_id,profile_id');
    }
  }

  /// Canale Realtime con listener su [tables]; [onEvent] riceve la riga nuova.
  Stream<T> _realtime<T>(
    String name,
    Map<String, PostgresChangeEvent> tables,
    Future<T?> Function(String table, Map<String, dynamic> row) onEvent,
  ) {
    late final StreamController<T> controller;
    RealtimeChannel? channel;
    controller = StreamController<T>(
      onListen: () {
        var c = _client.channel(name);
        tables.forEach((table, event) {
          c = c.onPostgresChanges(
            event: event,
            schema: 'public',
            table: table,
            callback: (payload) async {
              try {
                final out = await onEvent(table, payload.newRecord);
                if (out != null && !controller.isClosed) controller.add(out);
              } catch (_) {
                // Realtime è un di più: un evento perso non deve rompere nulla.
              }
            },
          );
        });
        channel = c.subscribe();
      },
      onCancel: () async {
        final c = channel;
        if (c != null) await _client.removeChannel(c);
      },
    );
    return controller.stream;
  }

  @override
  Stream<void> changes() => _realtime<void>('plans-live', const {
    'plans': PostgresChangeEvent.all,
    'votes': PostgresChangeEvent.all,
  }, (table, row) async => true).map((_) {});

  @override
  Stream<PlanAnnouncement> announcements({required String selfId}) => _realtime(
    'notifications',
    const {
      'plans': PostgresChangeEvent.insert,
      'votes': PostgresChangeEvent.all,
      'plan_cancellations': PostgresChangeEvent.insert,
    },
    (table, row) async {
      if (table == 'plan_cancellations') {
        return row['creator_id'] == selfId ? null : parseCancellation(row);
      }
      if (table == 'plans') {
        if (row['creator_id'] == selfId) return null;
        final full = await _client
            .from('plans')
            .select(
              'id, emoji, label, profiles!plans_creator_id_fkey(nickname), places(name)',
            )
            .eq('id', row['id'] as String)
            .single();
        return parseAnnouncement(full);
      }
      // Voti: solo quelli degli altri sui tuoi piani (i delete non hanno dati).
      final planId = row['plan_id'] as String?;
      final voterId = row['profile_id'] as String?;
      if (planId == null || voterId == null || voterId == selfId) return null;
      final full = await _client
          .from('votes')
          .select(
            'vote, profiles(nickname), plans(creator_id, emoji, label, places(name))',
          )
          .eq('plan_id', planId)
          .eq('profile_id', voterId)
          .single();
      return parseVoteAnnouncement(planId, full, selfId: selfId);
    },
  );

  /// Da una riga `plans` con creatore e luogo incorporati.
  static PlanAnnouncement parseAnnouncement(
    Map<String, dynamic> row,
  ) => PlanAnnouncement(
    planId: row['id'] as String,
    title:
        '${(row['profiles'] as Map<String, dynamic>)['nickname']} ha lanciato un piano',
    subtitle: _subtitle(row),
  );

  /// Da una riga `plan_cancellations`: "Marco ha annullato il piano".
  static PlanAnnouncement parseCancellation(
    Map<String, dynamic> row,
  ) => PlanAnnouncement(
    planId: row['plan_id'] as String,
    title: '${row['creator_nickname']} ha annullato il piano',
    subtitle:
        '${row['emoji']} ${row['label']} · ${row['place_name'] ?? unnamedPlaceName}',
    cancelled: true,
  );

  /// Da una riga `votes` con votante e piano incorporati; `null` se il piano non
  /// è tuo.
  static PlanAnnouncement? parseVoteAnnouncement(
    String planId,
    Map<String, dynamic> row, {
    required String selfId,
  }) {
    final plan = row['plans'] as Map<String, dynamic>;
    if (plan['creator_id'] != selfId) return null;
    final nick = (row['profiles'] as Map<String, dynamic>)['nickname'];
    return PlanAnnouncement(
      planId: planId,
      title: row['vote'] == 'yes' ? '$nick ci sta 🙋' : '$nick non ci sta 😴',
      subtitle: _subtitle(plan),
    );
  }

  static String _subtitle(Map<String, dynamic> planRow) {
    final place =
        ((planRow['places'] as Map<String, dynamic>?)?['name'] as String?) ??
        unnamedPlaceName;
    return '${planRow['emoji']} ${planRow['label']} · $place';
  }
}
