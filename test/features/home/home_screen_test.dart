import 'package:ciamafa/features/home/home_screen.dart';
import 'package:ciamafa/features/plans/activity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  late GoRouter router;

  setUp(() {
    router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
        GoRoute(
          path: '/places/:activityId',
          builder: (_, s) => Text('places:${s.pathParameters['activityId']}'),
        ),
      ],
    );
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  testWidgets('shows title and the 5 activities in fixed order, no header', (
    tester,
  ) async {
    await pump(tester);

    // Profilo e Piani si raggiungono dalla bottom nav, non più dalla Home.
    expect(find.text('V'), findsNothing);
    expect(find.text('📅 Impegni'), findsNothing);
    expect(find.byKey(const ValueKey('plans-badge')), findsNothing);
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
}
