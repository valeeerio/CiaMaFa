import 'package:ciamafa/core/theme.dart';
import 'package:ciamafa/shared/bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    int index = 0,
    int plans = 0,
    ValueChanged<int>? onTap,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        bottomNavigationBar: BottomNavBar(
          currentIndex: index,
          plansCount: plans,
          onTap: onTap ?? (_) {},
        ),
      ),
    ),
  );

  Color labelColor(WidgetTester tester, String label) =>
      tester.widget<Text>(find.text(label)).style!.color!;

  testWidgets('shows the four destinations in order', (tester) async {
    await pump(tester);
    final xs = [
      for (final l in ['Home', 'Piani', 'Chat', 'Profilo'])
        tester.getTopLeft(find.text(l)).dx,
    ];
    expect(xs, orderedEquals([...xs]..sort()));
    for (final e in ['🏠', '📅', '💬', '🙂']) {
      expect(find.text(e), findsOneWidget);
    }
  });

  testWidgets('active label is night blue, the others muted', (tester) async {
    await pump(tester, index: 2);
    expect(labelColor(tester, 'Chat'), AppColors.nightBlue);
    for (final l in ['Home', 'Piani', 'Profilo']) {
      expect(labelColor(tester, l), AppColors.muted);
    }
  });

  testWidgets('tapping a destination reports its index', (tester) async {
    final taps = <int>[];
    await pump(tester, onTap: taps.add);
    await tester.tap(find.text('Chat'));
    await tester.tap(find.text('Profilo'));
    await tester.tap(find.text('Home'));
    expect(taps, [2, 3, 0]);
  });

  testWidgets('plans badge shows the count and hides at zero', (tester) async {
    await pump(tester, plans: 0);
    expect(find.byKey(const ValueKey('plans-badge')), findsNothing);
    await pump(tester, plans: 3);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('plans-badge')),
        matching: find.text('3'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('badge is acid green', (tester) async {
    await pump(tester, plans: 2);
    final badge = tester.widget<CircleAvatar>(
      find.byKey(const ValueKey('plans-badge')),
    );
    expect(badge.backgroundColor, AppColors.acidGreen);
  });
}
