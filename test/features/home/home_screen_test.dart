import 'package:ciamafa/features/home/home_screen.dart';
import 'package:ciamafa/features/onboarding/onboarding_provider.dart';
import 'package:ciamafa/features/onboarding/profile_repository.dart';
import 'package:ciamafa/features/plans/activity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late MockProfileRepository repo;
  late GoRouter router;

  setUp(() {
    repo = MockProfileRepository();
    when(() => repo.fetchCurrentProfile()).thenAnswer(
      (_) async => const Profile(
        id: 'u1',
        nickname: 'valerio',
        notificationsEnabled: true,
      ),
    );
    router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
        GoRoute(
          path: '/places/:activityId',
          builder: (_, s) => Text('places:${s.pathParameters['activityId']}'),
        ),
        GoRoute(path: '/plans', builder: (_, _) => const Text('plans')),
        GoRoute(path: '/profile', builder: (_, _) => const Text('profile')),
      ],
    );
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [profileRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows header, title and the 5 activities in fixed order', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('V'), findsOneWidget); // iniziale del nickname
    expect(find.text('📅 Impegni'), findsOneWidget);
    expect(find.text('CiaMaFa?'), findsOneWidget);
    expect(find.text('Lancia un piano al gruppo.'), findsOneWidget);

    final ys = [
      for (final a in activities) tester.getTopLeft(find.text(a.label)).dy,
    ];
    expect(ys, orderedEquals([...ys]..sort()));
    expect(activities.map((a) => a.label), [
      'Bar',
      'Bombolone',
      'Posto Chill',
      'Mangiare',
      'Bho, vediamoci e decidiamo',
    ]);
  });

  for (final a in activities) {
    testWidgets('tapping ${a.label} opens /places/${a.id}', (tester) async {
      await pump(tester);
      await tester.tap(find.text(a.label));
      await tester.pumpAndSettle();
      expect(find.text('places:${a.id}'), findsOneWidget);
    });
  }

  testWidgets('avatar opens profile, pill opens plans', (tester) async {
    await pump(tester);
    await tester.tap(find.text('📅 Impegni'));
    await tester.pumpAndSettle();
    expect(find.text('plans'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('V'));
    await tester.pumpAndSettle();
    expect(find.text('profile'), findsOneWidget);
  });
}
