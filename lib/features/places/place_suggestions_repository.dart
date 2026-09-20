import 'package:supabase_flutter/supabase_flutter.dart';

import 'place_candidate.dart';

abstract interface class PlaceSuggestionsRepository {
  /// Preset dell'attività, GIÀ ORDINATI dal server: più scelti (piani lanciati
  /// + adesioni), poi più recenti, poi più vicini al centro del gruppo.
  /// Sono quelli scelti a mano (curati) o lanciati almeno 2 volte.
  Future<List<PlaceCandidate>> presetsFor(String activityId);
}

class SupabasePlaceSuggestionsRepository implements PlaceSuggestionsRepository {
  SupabasePlaceSuggestionsRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<PlaceCandidate>> presetsFor(String activityId) async {
    // La funzione è `security invoker`: il filtro per gruppo lo applica la RLS.
    final rows = await _client.rpc<List<dynamic>>(
      'activity_presets',
      params: {'p_activity_id': activityId},
    );
    return [
      for (final row in rows)
        PlaceCandidate.fromPresetRow(row as Map<String, dynamic>),
    ];
  }
}
