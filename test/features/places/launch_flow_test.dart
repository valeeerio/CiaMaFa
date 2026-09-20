import 'dart:async';

import 'package:ciamafa/features/places/location_service.dart';
import 'package:ciamafa/features/places/place_candidate.dart';
import 'package:ciamafa/features/places/place_search_repository.dart';
import 'package:ciamafa/features/places/place_suggestions_repository.dart';
import 'package:ciamafa/features/places/places_provider.dart';
import 'package:ciamafa/features/places/places_screen.dart';
import 'package:ciamafa/features/plans/activity.dart';
import 'package:ciamafa/features/plans/launched_screen.dart';
import 'package:ciamafa/features/plans/plans_provider.dart';
import 'package:ciamafa/features/plans/plans_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';

class MockSearch extends Mock implements PlaceSearchRepository {}

class MockSuggestions extends Mock implements PlaceSuggestionsRepository {}

class MockLocation extends Mock implements LocationService {}

class MockPlans extends Mock implements PlansRepository {}

const _piazza = PlaceCandidate(
  name: 'Piazza Aldo Moro',
  lat: 41.0389,
  lng: 16.7264,
);

void main() {
  late MockPlans plans;
  late MockSuggestions suggestions;

  setUpAll(() {
    registerFallbackValue(activities.first);
    registerFallbackValue(_piazza);
    registerFallbackValue(const LatLng(0, 0));
  });

  setUp(() {
    plans = MockPlans();
    suggestions = MockSuggestions();
    when(() => suggestions.presetsFor(any()))
        .thenAnswer((_) async => [_piazza]);
  });

  void launchReturns(LaunchResult r) => when(
    () => plans.launch(
      activity: any(named: 'activity'),
      place: any(named: 'place'),
      confirmExtra: any(named: 'confirmExtra'),
    ),
  ).thenAnswer((_) async => r);

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final search = MockSearch();
    when(() => search.streetAt(any())).thenAnswer((_) async => null);
    final router = GoRouter(
      initialLocation: '/places/bar',
      routes: [
        GoRoute(
          path: '/places/:activityId',
          builder: (context, state) =>
              PlacesScreen(activityId: state.pathParameters['activityId']!),
        ),
        GoRoute(
          path: '/launched',
          builder: (context, state) =>
              Text('LANCIATO ${(state.extra! as LaunchedInfo).placeName}'),
        ),
        GoRoute(
          path: '/plans',
          builder: (context, state) => const Scaffold(body: Text('PIANI')),
        ),
        GoRoute(path: '/home', builder: (context, state) => const Text('HOME')),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          placeSearchRepositoryProvider.overrideWithValue(search),
          placeSuggestionsRepositoryProvider.overrideWithValue(suggestions),
          locationServiceProvider.overrideWithValue(MockLocation()),
          plansRepositoryProvider.overrideWithValue(plans),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-places')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('row:Piazza Aldo Moro')));
    await tester.pumpAndSettle();
  }

  Future<void> tapLaunch(WidgetTester tester) async {
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
  }

  void expectLaunchCalled({required bool confirmExtra, int times = 1}) =>
      verify(
        () => plans.launch(
          activity: any(
            named: 'activity',
            that: isA<Activity>().having((a) => a.id, 'id', 'bar'),
          ),
          place: any(
            named: 'place',
            that: isA<PlaceCandidate>().having(
              (p) => p.name,
              'name',
              'Piazza Aldo Moro',
            ),
          ),
          confirmExtra: confirmExtra,
        ),
      ).called(times);

  testWidgets('launched: goes to "Piano lanciato" with the place name', (
    tester,
  ) async {
    launchReturns(const Launched(planId: 'p1', placeName: 'Piazza Aldo Moro'));
    await pump(tester);
    await tapLaunch(tester);

    expect(find.text('LANCIATO Piazza Aldo Moro'), findsOneWidget);
    expectLaunchCalled(confirmExtra: false);
  });

  testWidgets('you already have a plan today: asks, "Annulla" does nothing', (
    tester,
  ) async {
    launchReturns(const NeedsConfirmation(1));
    await pump(tester);
    await tapLaunch(tester);

    expect(find.text('Hai già un piano per oggi'), findsOneWidget);
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();

    expect(find.text('Hai già un piano per oggi'), findsNothing);
    expect(find.text('LANCIATO Piazza Aldo Moro'), findsNothing);
    expectLaunchCalled(confirmExtra: false);
  });

  testWidgets('…and "Lancia lo stesso" launches with confirmExtra', (
    tester,
  ) async {
    when(
      () => plans.launch(
        activity: any(named: 'activity'),
        place: any(named: 'place'),
        confirmExtra: false,
      ),
    ).thenAnswer((_) async => const NeedsConfirmation(1));
    when(
      () => plans.launch(
        activity: any(named: 'activity'),
        place: any(named: 'place'),
        confirmExtra: true,
      ),
    ).thenAnswer(
      (_) async => const Launched(planId: 'p2', placeName: 'Piazza Aldo Moro'),
    );
    await pump(tester);
    await tapLaunch(tester);
    await tester.tap(find.text('Lancia lo stesso'));
    await tester.pumpAndSettle();

    expect(find.text('LANCIATO Piazza Aldo Moro'), findsOneWidget);
    expectLaunchCalled(confirmExtra: true);
  });

  testWidgets('a friend already proposed it: no launch, you see the plans', (
    tester,
  ) async {
    launchReturns(const DuplicatePlan('p9'));
    await pump(tester);
    await tapLaunch(tester);

    expect(find.text('PIANI'), findsOneWidget);
    expect(
      find.text('Questo posto è già stato proposto oggi.'),
      findsOneWidget,
    );
    expect(find.text('LANCIATO Piazza Aldo Moro'), findsNothing);
  });

  testWidgets('failure: says so, stays here, "Riprova" tries again', (
    tester,
  ) async {
    var calls = 0;
    when(
      () => plans.launch(
        activity: any(named: 'activity'),
        place: any(named: 'place'),
        confirmExtra: any(named: 'confirmExtra'),
      ),
    ).thenAnswer((_) async {
      calls++;
      if (calls == 1) throw Exception('offline');
      return const Launched(planId: 'p3', placeName: 'Piazza Aldo Moro');
    });
    await pump(tester);
    await tapLaunch(tester);

    expect(find.text('Non sono riuscito a lanciare il piano.'), findsOneWidget);
    expect(find.text('Dove?'), findsOneWidget); // ancora sulla mappa
    // Il pulsante si può ritoccare (non resta bloccato).
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );

    await tester.tap(find.text('Riprova'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('LANCIATO Piazza Aldo Moro'), findsOneWidget);
  });

  testWidgets('while launching the button is disabled: no double launch', (
    tester,
  ) async {
    final pending = Completer<LaunchResult>();
    when(
      () => plans.launch(
        activity: any(named: 'activity'),
        place: any(named: 'place'),
        confirmExtra: any(named: 'confirmExtra'),
      ),
    ).thenAnswer((_) => pending.future);
    await pump(tester);

    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    pending.complete(
      const Launched(planId: 'p4', placeName: 'Piazza Aldo Moro'),
    );
    await tester.pumpAndSettle();
    expectLaunchCalled(confirmExtra: false);
  });
}
