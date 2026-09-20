import 'package:ciamafa/features/plans/plan_banner_host.dart';
import 'package:ciamafa/features/plans/plans_provider.dart';
import 'package:ciamafa/features/plans/plans_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _ann = PlanAnnouncement(
  planId: 'p1',
  nickname: 'Marco',
  emoji: '🍻',
  label: 'Bar',
  placeName: 'Pineta',
);

void main() {
  Future<ProviderContainer> pump(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        planAnnouncementsProvider.overrideWith((ref) => const Stream.empty()),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: PlanBannerHost(child: Scaffold(body: Text('sotto'))),
        ),
      ),
    );
    return container;
  }

  testWidgets('shows who launched what and where, then closes with ✕', (
    tester,
  ) async {
    final c = await pump(tester);
    expect(find.text('Marco ha lanciato un piano'), findsNothing);

    c.read(planBannerProvider.notifier).show(_ann);
    await tester.pumpAndSettle();
    expect(find.text('Marco ha lanciato un piano'), findsOneWidget);
    expect(find.text('🍻 Bar · Pineta'), findsOneWidget);

    await tester.tap(find.byTooltip('Chiudi'));
    await tester.pumpAndSettle();
    expect(find.text('Marco ha lanciato un piano'), findsNothing);
    expect(find.text('sotto'), findsOneWidget);
  });

  testWidgets('goes away by itself after a few seconds', (tester) async {
    final c = await pump(tester);
    c.read(planBannerProvider.notifier).show(_ann);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Marco ha lanciato un piano'), findsOneWidget);

    await tester.pump(bannerDuration);
    await tester.pumpAndSettle();
    expect(find.text('Marco ha lanciato un piano'), findsNothing);
  });
}
