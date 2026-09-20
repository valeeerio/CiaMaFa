import 'package:ciamafa/shared/staggered_entrance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app({bool reduced = false, int index = 0}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduced),
    child: Center(
      child: StaggeredEntrance(index: index, child: const Text('pin')),
    ),
  ),
);

double _opacity(WidgetTester tester) => tester
    .widget<Opacity>(
      find.ancestor(of: find.text('pin'), matching: find.byType(Opacity)).first,
    )
    .opacity;

void main() {
  testWidgets('fades in over time and ends fully visible', (tester) async {
    await tester.pumpWidget(_app());
    expect(_opacity(tester), 0);

    await tester.pump(); // avvia il ticker
    await tester.pump(const Duration(milliseconds: 25));
    final mid = _opacity(tester);
    expect(mid, inExclusiveRange(0, 1));

    await tester.pumpAndSettle();
    expect(_opacity(tester), 1);
  });

  testWidgets('later indexes start later (cascade)', (tester) async {
    await tester.pumpWidget(_app(index: 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 25));
    final first = _opacity(tester);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(_app(index: 6));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 25));
    expect(_opacity(tester), lessThan(first));

    await tester.pumpAndSettle();
  });

  testWidgets('reduced motion shows it immediately, without timers', (
    tester,
  ) async {
    await tester.pumpWidget(_app(reduced: true, index: 5));
    expect(_opacity(tester), 1);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
