import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/supabase_client.dart';
import 'location_service.dart';
import 'place_candidate.dart';
import 'place_search_repository.dart';
import 'place_suggestions_repository.dart';

part 'places_provider.g.dart';

const searchDebounce = Duration(milliseconds: 400);
const searchMinChars = 3;

@Riverpod(keepAlive: true)
PlaceSearchRepository placeSearchRepository(Ref ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return PhotonPlaceSearchRepository(client);
}

@Riverpod(keepAlive: true)
PlaceSuggestionsRepository placeSuggestionsRepository(Ref ref) =>
    SupabasePlaceSuggestionsRepository(supabase);

@Riverpod(keepAlive: true)
LocationService locationService(Ref ref) => GeolocatorLocationService();

/// Preset per l'attività: luoghi più usati dal gruppo.
@riverpod
Future<List<PlaceCandidate>> suggestedPlaces(Ref ref, String activityId) =>
    ref.watch(placeSuggestionsRepositoryProvider).topForActivity(activityId);

/// Luogo scelto (in memoria fino al lancio, Fase 4).
@riverpod
class PlaceSelection extends _$PlaceSelection {
  @override
  PlaceCandidate? build() => null;

  void select(PlaceCandidate? place) => state = place;
}

/// Ricerca con debounce; ignora le risposte di query superate.
@riverpod
class PlaceSearch extends _$PlaceSearch {
  Timer? _debounce;
  int _seq = 0;

  @override
  AsyncValue<List<PlaceCandidate>> build() {
    ref.onDispose(() => _debounce?.cancel());
    return const AsyncData([]);
  }

  void onQueryChanged(String text, {LatLng? near}) {
    _debounce?.cancel();
    final query = text.trim();
    final seq = ++_seq;
    if (query.length < searchMinChars) {
      state = const AsyncData([]);
      return;
    }
    state = const AsyncLoading();
    _debounce = Timer(searchDebounce, () async {
      final result = await AsyncValue.guard(
        () => ref.read(placeSearchRepositoryProvider).search(query, near: near),
      );
      if (ref.mounted && seq == _seq) state = result;
    });
  }

  void clear() {
    _debounce?.cancel();
    _seq++;
    state = const AsyncData([]);
  }
}
