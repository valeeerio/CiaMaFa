import 'package:supabase_flutter/supabase_flutter.dart';

import 'place_candidate.dart';

abstract interface class PlaceSuggestionsRepository {
  /// Luoghi più usati dal gruppo per l'attività (max [limit]).
  Future<List<PlaceCandidate>> topForActivity(
    String activityId, {
    int limit = 8,
  });
}

class SupabasePlaceSuggestionsRepository implements PlaceSuggestionsRepository {
  SupabasePlaceSuggestionsRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<PlaceCandidate>> topForActivity(
    String activityId, {
    int limit = 8,
  }) async {
    // Il filtro per gruppo lo applica la RLS di place_activity_stats.
    final rows = await _client
        .from('place_activity_stats')
        .select('times_used, last_used_at, places(*)')
        .eq('activity_id', activityId)
        .order('times_used', ascending: false)
        .order('last_used_at', ascending: false)
        .limit(limit);
    return [
      for (final row in rows)
        if (row['places'] case final Map<String, dynamic> p)
          PlaceCandidate(
            name: p['name'] as String,
            address: p['address'] as String?,
            lat: (p['lat'] as num).toDouble(),
            lng: (p['lng'] as num).toDouble(),
            externalSource: p['external_source'] as String?,
            externalId: p['external_id'] as String?,
          ),
    ];
  }
}
