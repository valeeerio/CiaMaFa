import 'package:ciamafa/features/places/location_service.dart';
import 'package:ciamafa/features/places/place_candidate.dart';
import 'package:ciamafa/features/places/place_search_repository.dart';
import 'package:ciamafa/features/places/place_suggestions_repository.dart';
import 'package:ciamafa/features/places/places_provider.dart';
import 'package:ciamafa/features/places/places_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSearch extends Mock implements PlaceSearchRepository {}

class MockSuggestions extends Mock implements PlaceSuggestionsRepository {}

class MockLocation extends Mock implements LocationService {}

const _piazza = PlaceCandidate(
  name: 'Piazza Aldo Moro',
  address: 'Bitetto',
  lat: 41.0389,
  lng: 16.7264,
);
const _bar = PlaceCandidate(
  name: 'Bar Centrale',
  address: 'Via Roma 12',
  lat: 41.04,
  lng: 16.73,
);

void main() {
  late MockSearch search;
  late MockSuggestions suggestions;
  late MockLocation location;

  setUp(() {
    search = MockSearch();
    suggestions = MockSuggestions();
    location = MockLocation();
    when(() => suggestions.topForActivity(any(), limit: any(named: 'limit')))
        .thenAnswer((_) async => [_piazza]);
    when(() => location.currentPosition()).thenAnswer((_) async => null);
  });

  Future<void> pump(WidgetTester tester, String activityId) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          placeSearchRepositoryProvider.overrideWithValue(search),
          placeSuggestionsRepositoryProvider.overrideWithValue(suggestions),
          locationServiceProvider.overrideWithValue(location),
        ],
        child: MaterialApp(home: PlacesScreen(activityId: activityId)),
      ),
    );
    await tester.pumpAndSettle();
  }

  FilledButton cta(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byType(FilledButton));

  testWidgets(
    'shows per-activity title and CTA text, CTA disabled without a place',
    (tester) async {
      await pump(tester, 'bar');
      expect(find.text('Dove andiamo al bar?'), findsOneWidget);
      expect(find.text('Lancia Bar qui 🚀'), findsOneWidget);
      expect(cta(tester).onPressed, isNull);
    },
  );

  testWidgets('Bho uses its own title and CTA', (tester) async {
    await pump(tester, 'bho');
    expect(find.text('Intanto dove ci vediamo?'), findsOneWidget);
    expect(find.text('Lanciamo e decidiamo lì 🚀'), findsOneWidget);
  });

  testWidgets('tapping a preset chip selects it and enables the CTA', (
    tester,
  ) async {
    await pump(tester, 'bar');
    expect(find.text('📍 La tua posizione'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('chip:Piazza Aldo Moro')));
    await tester.pumpAndSettle();

    expect(find.text('Bitetto'), findsOneWidget); // card riepilogo
    expect(cta(tester).onPressed, isNotNull);
  });

  testWidgets('search shows results and picking one selects it', (
    tester,
  ) async {
    when(() => search.search('bar', near: any(named: 'near')))
        .thenAnswer((_) async => [_bar]);
    await pump(tester, 'bar');

    await tester.enterText(find.byType(TextField), 'bar');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ListTile, 'Bar Centrale'), findsOneWidget);

    await tester.tap(find.widgetWithText(ListTile, 'Bar Centrale'));
    await tester.pumpAndSettle();

    expect(find.text('Via Roma 12'), findsOneWidget);
    expect(cta(tester).onPressed, isNotNull);
  });

  testWidgets('locate without permission shows a message', (tester) async {
    await pump(tester, 'bar');
    await tester.tap(find.text('🎯'));
    await tester.pumpAndSettle();
    expect(find.textContaining('permessi di posizione'), findsOneWidget);
  });
}
