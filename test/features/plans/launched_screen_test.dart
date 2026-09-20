import 'package:ciamafa/core/theme.dart';
import 'package:ciamafa/features/plans/activity.dart';
import 'package:ciamafa/features/plans/launched_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  final info = LaunchedInfo(
    activity: activityById('bar'),
    placeName: 'Pineta',
    planId: 'p1',
  );

  Future<GoRouter> pump(WidgetTester tester, {bool reduced = false}) async {
    final router = GoRouter(
      initialLocation: '/launched',
      routes: [
        GoRoute(
          path: '/launched',
          builder: (context, state) => LaunchedScreen(info: info),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const Text('HOME'),
          routes: const [],
        ),
        GoRoute(
          path: '/plans',
          builder: (context, state) => const Text('PIANI'),
        ),
        GoRoute(
          path: '/plans/:id',
          builder: (context, state) =>
              Text('PIANO ${state.pathParameters['id']}'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
          child: child!,
        ),
      ),
    );
    await tester.pump();
    return router;
  }

  double confettiProgress(WidgetTester tester) {
    final paint = tester.widget<CustomPaint>(
      find.byKey(const ValueKey('confetti')),
    );
    return (paint.painter! as dynamic).t as double;
  }

  testWidgets('shows the summary and the expiry on night blue', (tester) async {
    await pump(tester);
    expect(find.text('Piano lanciato!'), findsOneWidget);
    expect(
      find.text('Il gruppo ha ricevuto una notifica per 🍻 Bar a Pineta.'),
      findsOneWidget,
    );
    expect(find.text('Scade stanotte a mezzanotte'), findsOneWidget);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      AppColors.nightBlue,
    );
    await tester.pumpAndSettle();
  });

  testWidgets('confetti fall once and finish', (tester) async {
    await pump(tester);
    await tester.pump(const Duration(milliseconds: 800));
    expect(confettiProgress(tester), inExclusiveRange(0, 1));
    await tester.pumpAndSettle();
    expect(confettiProgress(tester), 1);
  });

  testWidgets('reduced motion: no confetti at all', (tester) async {
    await pump(tester, reduced: true);
    await tester.pump(const Duration(milliseconds: 800));
    expect(confettiProgress(tester), 0);
  });

  testWidgets('"Torna alla home" goes home', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Torna alla home'));
    await tester.pumpAndSettle();
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets(
    '"Vedi piano" opens the new plan, with list and Home underneath',
    (tester) async {
      final router = await pump(tester);
      await tester.tap(find.text('Vedi piano'));
      await tester.pumpAndSettle();
      expect(find.text('PIANO p1'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('PIANI'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('HOME'), findsOneWidget);
    },
  );
}
