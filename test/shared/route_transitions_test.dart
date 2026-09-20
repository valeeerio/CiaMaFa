import 'package:ciamafa/shared/route_transitions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _origin = TransitionOrigin(
  rect: Rect.fromLTWH(24, 300, 340, 80),
  color: Color(0xFFFF8C42),
  radius: 22,
);

GoRouter _router({TransitionOrigin? origin}) => GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, _) => Scaffold(
        body: TextButton(
          onPressed: () => context.push('/detail', extra: origin),
          child: const Text('open'),
        ),
      ),
    ),
    GoRoute(
      path: '/detail',
      pageBuilder: (context, state) => expandingPage(
        key: state.pageKey,
        origin: state.extra as TransitionOrigin?,
        child: const Scaffold(body: Center(child: Text('detail'))),
      ),
    ),
  ],
);

Widget _app(GoRouter router, {bool reduced = false}) => MaterialApp.router(
  routerConfig: router,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
    child: child!,
  ),
);

Finder get _grownBox => find.byWidgetPredicate(
  (w) =>
      w is DecoratedBox &&
      w.decoration is BoxDecoration &&
      (w.decoration as BoxDecoration).color == _origin.color,
);

void main() {
  testWidgets('expands the origin box while opening, then shows the page', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_router(origin: _origin)));
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(_grownBox, findsOneWidget); // rettangolo colorato in espansione
    final mid = tester.getRect(_grownBox);
    expect(mid.width, greaterThan(_origin.rect.width));

    await tester.pumpAndSettle();
    expect(find.text('detail'), findsOneWidget);
    expect(
      tester
          .widget<Opacity>(
            find
                .ancestor(
                  of: find.text('detail'),
                  matching: find.byType(Opacity),
                )
                .first,
          )
          .opacity,
      1,
    );
  });

  testWidgets('closes back onto the button', (tester) async {
    final router = _router(origin: _origin);
    await tester.pumpWidget(_app(router));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
    expect(find.text('detail'), findsNothing);
  });

  testWidgets('reduced motion or missing origin falls back to a fade', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_router(origin: _origin), reduced: true));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('detail'), findsOneWidget);
    expect(_grownBox, findsNothing);
  });
}
