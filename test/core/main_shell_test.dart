import 'package:ciamafa/features/plans/plan.dart';
import 'package:ciamafa/features/plans/plans_provider.dart';
import 'package:ciamafa/features/plans/plans_repository.dart';
import 'package:ciamafa/shared/bottom_nav_bar.dart';
import 'package:ciamafa/shared/main_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockPlans extends Mock implements PlansRepository {}

Plan _plan(String id) => Plan(
  id: id,
  activityId: 'bar',
  emoji: '🍻',
  label: 'Bar',
  creatorId: 'x',
  creatorNickname: 'Marco',
  createdAt: DateTime(2026, 9, 20, 18),
  place: null,
  votes: const [],
);

/// Stessa struttura del router dell'app, con schermate finte.
void main() {
  late MockPlans plans;
  late GoRouter router;
  var todays = <Plan>[];

  setUp(() {
    plans = MockPlans();
    todays = [];
    when(() => plans.todaysPlans()).thenAnswer((_) async => todays);
    when(() => plans.changes()).thenAnswer((_) => const Stream.empty());
    final rootKey = GlobalKey<NavigatorState>();
    router = GoRouter(
      navigatorKey: rootKey,
      initialLocation: '/home',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (_, _, shell) => MainShell(navigationShell: shell),
          branches: [
            for (final path in ['/home', '/plans', '/chat', '/profile'])
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: path,
                    builder: (context, _) => Scaffold(
                      body: Column(
                        children: [
                          Text('tab:$path'),
                          TextButton(
                            onPressed: () => context.push('/plans/p1'),
                            child: Text('open:$path'),
                          ),
                          TextField(key: ValueKey('field:$path')),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
        GoRoute(
          path: '/plans/:id',
          parentNavigatorKey: rootKey,
          builder: (_, s) => Text('detail:${s.pathParameters['id']}'),
        ),
      ],
    );
    addTearDown(router.dispose);
  });

  Future<void> pump(WidgetTester tester, {double keyboard = 0}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [plansRepositoryProvider.overrideWithValue(plans)],
        child: MaterialApp.router(
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(viewInsets: EdgeInsets.only(bottom: keyboard)),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('tapping a tab switches to it and shows the nav bar', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('tab:/home'), findsOneWidget);
    for (final (label, path) in [
      ('Chat', '/chat'),
      ('Profilo', '/profile'),
      ('Piani', '/plans'),
      ('Home', '/home'),
    ]) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(find.text('tab:$path'), findsOneWidget);
      expect(find.byType(BottomNavBar), findsOneWidget);
    }
  });

  testWidgets('a tab keeps its state when you switch away and back', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('field:/chat')), 'ciao');
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();
    expect(find.text('ciao'), findsOneWidget);
  });

  testWidgets('stack screens cover the nav bar and back returns to the tab', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('Piani'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open:/plans'));
    await tester.pumpAndSettle();
    expect(find.text('detail:p1'), findsOneWidget);
    expect(find.byType(BottomNavBar), findsNothing);
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('tab:/plans'), findsOneWidget);
    expect(find.byType(BottomNavBar), findsOneWidget);
  });

  testWidgets('the Piani badge follows the number of plans today', (
    tester,
  ) async {
    todays = [_plan('a'), _plan('b')];
    await pump(tester);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('plans-badge')),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the nav bar steps aside while the keyboard is open', (
    tester,
  ) async {
    await pump(tester, keyboard: 300);
    expect(find.byType(BottomNavBar), findsNothing);
    await pump(tester);
    expect(find.byType(BottomNavBar), findsOneWidget);
  });
}
