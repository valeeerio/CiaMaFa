import 'package:ciamafa/features/places/place_candidate.dart';
import 'package:ciamafa/features/places/place_search_repository.dart';
import 'package:ciamafa/features/places/places_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSearchRepo extends Mock implements PlaceSearchRepository {}

const _bar = PlaceCandidate(name: 'Bar Centrale', lat: 41, lng: 16);

void main() {
  late MockSearchRepo repo;
  late ProviderContainer container;
  const wait = Duration(milliseconds: 500); // > searchDebounce

  setUp(() {
    repo = MockSearchRepo();
    container = ProviderContainer(
      overrides: [placeSearchRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    container.listen(
      placeSearchProvider,
      (_, _) {},
    ); // tiene vivo l'autoDispose
  });

  test('queries shorter than 3 chars do not hit the repository', () async {
    container.read(placeSearchProvider.notifier).onQueryChanged('ba');
    await Future<void>.delayed(wait);

    verifyNever(() => repo.search(any(), near: any(named: 'near')));
    expect(container.read(placeSearchProvider).value, isEmpty);
  });

  test('debounce: only the last query is sent', () async {
    when(() => repo.search('bar', near: any(named: 'near')))
        .thenAnswer((_) async => [_bar]);
    final n = container.read(placeSearchProvider.notifier);

    n.onQueryChanged('bar');
    n.onQueryChanged('bar ');
    n.onQueryChanged('bar');
    await Future<void>.delayed(wait);

    verify(() => repo.search('bar', near: any(named: 'near'))).called(1);
    expect(container.read(placeSearchProvider).value, [_bar]);
  });

  test('errors are exposed and clear() resets results', () async {
    when(() => repo.search(any(), near: any(named: 'near')))
        .thenThrow(Exception('offline'));
    final n = container.read(placeSearchProvider.notifier);

    n.onQueryChanged('bar');
    await Future<void>.delayed(wait);
    expect(container.read(placeSearchProvider).hasError, isTrue);

    n.clear();
    expect(container.read(placeSearchProvider).value, isEmpty);
  });

  test('selection notifier stores the chosen place', () {
    container.read(placeSelectionProvider.notifier).select(_bar);
    expect(container.read(placeSelectionProvider), _bar);
  });
}
