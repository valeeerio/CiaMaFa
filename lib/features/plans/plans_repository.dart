import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants.dart';
import '../places/place_candidate.dart';
import 'activity.dart';

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

/// Un nuovo piano lanciato da un altro membro del gruppo.
class PlanAnnouncement {
  const PlanAnnouncement({
    required this.planId,
    required this.nickname,
    required this.emoji,
    required this.label,
    required this.placeName,
  });

  final String planId;
  final String nickname;
  final String emoji;
  final String label;
  final String placeName;
}

abstract interface class PlansRepository {
  /// Lancia il piano per [activity] in [place]. Se hai già piani attivi oggi
  /// serve [confirmExtra] (altrimenti [NeedsConfirmation]).
  Future<LaunchResult> launch({
    required Activity activity,
    required PlaceCandidate place,
    bool confirmExtra = false,
  });

  /// Nuovi piani degli ALTRI membri, in tempo reale (app aperta).
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

  @override
  Stream<PlanAnnouncement> announcements({required String selfId}) {
    late final StreamController<PlanAnnouncement> controller;
    RealtimeChannel? channel;

    Future<void> onInsert(Map<String, dynamic> row) async {
      if (row['creator_id'] == selfId) return;
      try {
        final full = await _client
            .from('plans')
            .select('id, emoji, label, profiles(nickname), places(name)')
            .eq('id', row['id'] as String)
            .single();
        controller.add(parseAnnouncement(full));
      } catch (_) {
        // Il banner è un di più: se il dettaglio non arriva, niente banner.
      }
    }

    controller = StreamController<PlanAnnouncement>(
      onListen: () {
        channel = _client
            .channel('new-plans')
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'plans',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'group_id',
                value: defaultGroupId,
              ),
              callback: (payload) => onInsert(payload.newRecord),
            )
            .subscribe();
      },
      onCancel: () async {
        final c = channel;
        if (c != null) await _client.removeChannel(c);
      },
    );
    return controller.stream;
  }

  /// Da una riga `plans` con `profiles(nickname)` e `places(name)` incorporati.
  static PlanAnnouncement parseAnnouncement(Map<String, dynamic> row) =>
      PlanAnnouncement(
        planId: row['id'] as String,
        nickname:
            (row['profiles'] as Map<String, dynamic>)['nickname'] as String,
        emoji: row['emoji'] as String,
        label: row['label'] as String,
        placeName:
            ((row['places'] as Map<String, dynamic>?)?['name'] as String?) ??
            unnamedPlaceName,
      );
}
