import 'dart:async';

import 'package:ciamafa/core/theme.dart';
import 'package:ciamafa/features/onboarding/onboarding_provider.dart';
import 'package:ciamafa/features/onboarding/profile_repository.dart';
import 'package:ciamafa/features/plans/map_launcher.dart';
import 'package:ciamafa/features/plans/plan.dart';
import 'package:ciamafa/features/plans/plan_detail_screen.dart';
import 'package:ciamafa/features/plans/plans_provider.dart';
import 'package:ciamafa/features/plans/plans_repository.dart';
import 'package:ciamafa/features/plans/plans_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockPlans extends Mock implements PlansRepository {}

class MockProfiles extends Mock implements ProfileRepository {}

class MockMaps extends Mock implements MapLauncher {}

Plan plan(
  String id, {
  String activity = 'bar',
  String creator = 'Marco',
  String creatorId = 'u-marco',
  DateTime? at,
  List<PlanVote> votes = const [],
  String place = 'Pineta',
}) => Plan(
  id: id,
  activityId: activity,
  emoji: '🍻',
  label: 'Bar',
  creatorId: creatorId,
  creatorNickname: creator,
  createdAt: at ?? DateTime(2026, 9, 20, 18, 32),
  place: PlanPlace(name: place, address: 'Via X', lat: 41.03797, lng: 16.73744),
  votes: votes,
);

PlanVote yes(String id, String nick) =>
    PlanVote(profileId: id, nickname: nick, choice: VoteChoice.yes);
PlanVote no(String id, String nick) =>
    PlanVote(profileId: id, nickname: nick, choice: VoteChoice.no);

void main() {
  late MockPlans repo;
  late MockMaps maps;
  late List<Plan> current;

  setUpAll(() => registerFallbackValue(VoteChoice.yes));

  setUp(() {
    repo = MockPlans();
    maps = MockMaps();
    current = [];
    when(() => repo.todaysPlans()).thenAnswer((_) async => current);
    when(() => repo.changes()).thenAnswer((_) => const Stream.empty());
    when(
      () => repo.setVote(
        planId: any(named: 'planId'),
        profileId: any(named: 'profileId'),
        choice: any(named: 'choice'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => maps.open(
        lat: any(named: 'lat'),
        lng: any(named: 'lng'),
        label: any(named: 'label'),
      ),
    ).thenAnswer((_) async => true);
  });

  Future<void> pump(WidgetTester tester, String location) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final profiles = MockProfiles();
    when(() => profiles.fetchCurrentProfile()).thenAnswer(
      (_) async => const Profile(
        id: 'me',
        nickname: 'Valerio',
        notificationsEnabled: true,
      ),
    );
    final router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(path: '/plans', builder: (_, _) => const PlansScreen()),
        GoRoute(
          path: '/plans/:id',
          builder: (_, s) => PlanDetailScreen(planId: s.pathParameters['id']!),
        ),
        GoRoute(path: '/home', builder: (_, _) => const Text('HOME')),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null, // come l'app: gli errori emergono subito
        overrides: [
          plansRepositoryProvider.overrideWithValue(repo),
          profileRepositoryProvider.overrideWithValue(profiles),
          mapLauncherProvider.overrideWithValue(maps),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Piani di oggi', () {
    testWidgets('empty: 🫥 and "Lancia il primo?" goes to the Home', (
      tester,
    ) async {
      await pump(tester, '/plans');
      expect(find.text('Piani di oggi'), findsOneWidget);
      expect(find.text('Nessun piano per oggi.'), findsOneWidget);
      expect(find.text('Cercavi un piano di ieri sera?'), findsNothing);

      await tester.tap(find.text('Lancia il primo? 🚀'));
      await tester.pumpAndSettle();
      expect(find.text('HOME'), findsOneWidget);
    });

    testWidgets('a card shows activity, place, creator, time and counts', (
      tester,
    ) async {
      current = [
        plan('p1', votes: [yes('a', 'A'), yes('b', 'B'), no('c', 'C')]),
      ];
      await pump(tester, '/plans');

      expect(find.text('Bar · Pineta'), findsOneWidget);
      expect(find.text('di Marco · 18:32'), findsOneWidget);
      expect(find.text('🙋 2'), findsOneWidget);
      expect(find.text('😴 1'), findsOneWidget);
    });

    testWidgets('cards keep the order given by the repository', (tester) async {
      current = [
        plan('a', place: 'Prima', votes: [yes('x', 'X')]),
        plan('b', place: 'Seconda'),
      ];
      await pump(tester, '/plans');
      expect(
        tester.getTopLeft(find.text('Bar · Prima')).dy,
        lessThan(tester.getTopLeft(find.text('Bar · Seconda')).dy),
      );
    });

    testWidgets('a card uses the colour of its activity', (tester) async {
      current = [plan('a', activity: 'mangiare')];
      await pump(tester, '/plans');
      final box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byKey(const ValueKey('plan:a')),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect((box.decoration as BoxDecoration).color, AppColors.acidGreen);
    });

    testWidgets('tapping a card opens its detail', (tester) async {
      current = [
        plan('p1', votes: [yes('u-marco', 'Marco')]),
      ];
      await pump(tester, '/plans');
      await tester.tap(find.byKey(const ValueKey('plan:p1')));
      await tester.pumpAndSettle();
      expect(find.text('Proposto da Marco'), findsOneWidget);
    });

    testWidgets('live: a change on the server refreshes the list', (
      tester,
    ) async {
      final changes = StreamController<void>();
      addTearDown(changes.close);
      when(() => repo.changes()).thenAnswer((_) => changes.stream);
      current = [plan('p1', place: 'Pineta')];
      await pump(tester, '/plans');
      expect(find.text('Bar · Pineta'), findsOneWidget);

      current = [plan('p1', place: 'Pineta'), plan('p2', place: 'Frida')];
      changes.add(null);
      await tester.pumpAndSettle();
      expect(find.text('Bar · Frida'), findsOneWidget);
    });

    testWidgets('a failure says so and "Riprova" reloads', (tester) async {
      var calls = 0;
      when(() => repo.todaysPlans()).thenAnswer((_) async {
        calls++;
        if (calls == 1) throw Exception('offline');
        return [plan('p1')];
      });
      await pump(tester, '/plans');
      expect(find.text('Non riesco a caricare i piani.'), findsOneWidget);

      await tester.tap(find.text('Riprova'));
      await tester.pumpAndSettle();
      expect(find.text('Bar · Pineta'), findsOneWidget);
    });
  });

  group('Dettaglio del piano', () {
    testWidgets('shows creator, activity, place and time', (tester) async {
      current = [plan('p1')];
      await pump(tester, '/plans/p1');
      expect(find.text('Proposto da Marco'), findsOneWidget);
      expect(find.text('🍻 Bar'), findsOneWidget);
      expect(find.text('Pineta'), findsOneWidget);
      expect(find.text('Via X'), findsOneWidget);
      expect(find.text('alle 18:32'), findsOneWidget);
    });

    testWidgets('voter chips: names in two lists, "Nessuno ancora." if empty', (
      tester,
    ) async {
      current = [
        plan('p1', votes: [yes('a', 'Anna'), yes('b', 'Bea')]),
      ];
      await pump(tester, '/plans/p1');

      expect(find.text('🙋 Ci sono · 2'), findsOneWidget);
      expect(find.byKey(const ValueKey('voter:Anna')), findsOneWidget);
      expect(find.byKey(const ValueKey('voter:Bea')), findsOneWidget);
      expect(find.text('😴 Non ci sono · 0'), findsOneWidget);
      expect(find.text('Nessuno ancora.'), findsOneWidget);
    });

    testWidgets('your own chip is highlighted', (tester) async {
      current = [
        plan('p1', votes: [yes('me', 'Valerio'), yes('b', 'Bea')]),
      ];
      await pump(tester, '/plans/p1');
      Color? bg(String nick) =>
          ((tester
                      .widget<DecoratedBox>(find.byKey(ValueKey('voter:$nick')))
                      .decoration)
                  as BoxDecoration)
              .color;
      expect(bg('Valerio'), AppColors.nightBlue);
      expect(bg('Bea'), AppColors.white);
    });

    testWidgets('"Ci sono" votes yes, then shows ✓ once the server confirms', (
      tester,
    ) async {
      current = [plan('p1')];
      await pump(tester, '/plans/p1');
      expect(find.text('Ci sono 🙋'), findsOneWidget);

      current = [
        plan('p1', votes: [yes('me', 'Valerio')]),
      ];
      await tester.tap(find.byKey(const ValueKey('vote-yes')));
      await tester.pumpAndSettle();

      verify(
        () =>
            repo.setVote(planId: 'p1', profileId: 'me', choice: VoteChoice.yes),
      ).called(1);
      expect(find.text('✓ Ci sono 🙋'), findsOneWidget);
      expect(find.text('🙋 Ci sono · 1'), findsOneWidget);
    });

    testWidgets('tapping your vote again removes it', (tester) async {
      current = [
        plan('p1', votes: [yes('me', 'Valerio')]),
      ];
      await pump(tester, '/plans/p1');
      expect(find.text('✓ Ci sono 🙋'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('vote-yes')));
      await tester.pumpAndSettle();
      verify(() => repo.setVote(planId: 'p1', profileId: 'me', choice: null))
          .called(1);
    });

    testWidgets('changing your mind votes the other way', (tester) async {
      current = [
        plan('p1', votes: [yes('me', 'Valerio')]),
      ];
      await pump(tester, '/plans/p1');
      await tester.tap(find.byKey(const ValueKey('vote-no')));
      await tester.pumpAndSettle();
      verify(
        () =>
            repo.setVote(planId: 'p1', profileId: 'me', choice: VoteChoice.no),
      ).called(1);
    });

    testWidgets('while a vote is in flight both buttons are disabled', (
      tester,
    ) async {
      final pending = Completer<void>();
      when(
        () => repo.setVote(
          planId: any(named: 'planId'),
          profileId: any(named: 'profileId'),
          choice: any(named: 'choice'),
        ),
      ).thenAnswer((_) => pending.future);
      current = [plan('p1')];
      await pump(tester, '/plans/p1');

      await tester.tap(find.byKey(const ValueKey('vote-yes')));
      await tester.pump();
      FilledButton button(String key) => tester.widget<FilledButton>(
        find.descendant(
          of: find.byKey(ValueKey(key)),
          matching: find.byType(FilledButton),
        ),
      );
      expect(button('vote-yes').onPressed, isNull);
      expect(button('vote-no').onPressed, isNull);

      pending.complete();
      await tester.pumpAndSettle();
      expect(button('vote-yes').onPressed, isNotNull);
    });

    testWidgets('a failing vote says so', (tester) async {
      when(
        () => repo.setVote(
          planId: any(named: 'planId'),
          profileId: any(named: 'profileId'),
          choice: any(named: 'choice'),
        ),
      ).thenThrow(Exception('offline'));
      current = [plan('p1')];
      await pump(tester, '/plans/p1');
      await tester.tap(find.byKey(const ValueKey('vote-yes')));
      await tester.pumpAndSettle();
      expect(
        find.text('Non sono riuscito a registrare il voto.'),
        findsOneWidget,
      );
    });

    testWidgets('a plan that is gone: "Questo piano non c\'è più"', (
      tester,
    ) async {
      current = [plan('other')];
      await pump(tester, '/plans/p1');
      expect(find.text('Questo piano non c\'è più'), findsOneWidget);
      expect(find.byKey(const ValueKey('vote-yes')), findsNothing);
    });

    testWidgets('live: the plan disappearing switches to the gone state', (
      tester,
    ) async {
      final changes = StreamController<void>();
      addTearDown(changes.close);
      when(() => repo.changes()).thenAnswer((_) => changes.stream);
      current = [plan('p1')];
      await pump(tester, '/plans/p1');
      expect(find.text('Proposto da Marco'), findsOneWidget);

      current = [];
      changes.add(null);
      await tester.pumpAndSettle();
      expect(find.text('Questo piano non c\'è più'), findsOneWidget);
    });

    testWidgets('the mini map opens the place in the maps app', (tester) async {
      current = [plan('p1')];
      await pump(tester, '/plans/p1');
      await tester.tap(find.byKey(const ValueKey('mini-map')));
      await tester.pump();
      verify(() => maps.open(lat: 41.03797, lng: 16.73744, label: 'Pineta'))
          .called(1);
    });
  });
}
