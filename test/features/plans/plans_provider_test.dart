import 'dart:async';

import 'package:ciamafa/features/onboarding/onboarding_provider.dart';
import 'package:ciamafa/features/onboarding/profile_repository.dart';
import 'package:ciamafa/features/plans/plans_provider.dart';
import 'package:ciamafa/features/plans/plans_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProfiles extends Mock implements ProfileRepository {}

class MockPlans extends Mock implements PlansRepository {}

const _ann = PlanAnnouncement(
  planId: 'p1',
  title: 'Marco ha lanciato un piano',
  subtitle: '🍻 Bar · Pineta',
);

void main() {
  late MockProfiles profiles;
  late MockPlans plans;
  late StreamController<PlanAnnouncement> feed;

  setUp(() {
    profiles = MockProfiles();
    plans = MockPlans();
    feed = StreamController<PlanAnnouncement>.broadcast();
    addTearDown(feed.close);
    when(() => plans.announcements(selfId: any(named: 'selfId')))
        .thenAnswer((_) => feed.stream);
  });

  ProviderContainer make({required bool notifications}) {
    when(() => profiles.fetchCurrentProfile()).thenAnswer(
      (_) async => Profile(
        id: 'me',
        nickname: 'Valerio',
        notificationsEnabled: notifications,
      ),
    );
    final c = ProviderContainer(
      overrides: [
        profileRepositoryProvider.overrideWithValue(profiles),
        plansRepositoryProvider.overrideWithValue(plans),
      ],
    );
    addTearDown(c.dispose);
    // Come fa PlanBannerHost: qualcuno ascolta il banner (altrimenti è in pausa).
    c.listen(planBannerProvider, (_, _) {});
    return c;
  }

  test('a friend\'s new plan shows the banner; dismiss clears it', () async {
    final c = make(notifications: true);
    await c.read(currentProfileProvider.future);
    expect(c.read(planBannerProvider), isNull);

    await Future<void>.delayed(const Duration(milliseconds: 20));
    feed.add(_ann);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(c.read(planBannerProvider)?.title, 'Marco ha lanciato un piano');

    c.read(planBannerProvider.notifier).dismiss();
    expect(c.read(planBannerProvider), isNull);
    verify(() => plans.announcements(selfId: 'me')).called(1);
  });

  test('a newer plan replaces the banner', () async {
    final c = make(notifications: true);
    await c.read(currentProfileProvider.future);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    feed.add(_ann);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    feed.add(
      const PlanAnnouncement(
        planId: 'p2',
        title: 'Anna ci sta 🙋',
        subtitle: '🍽️ Mangiare · Frida',
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(c.read(planBannerProvider)?.planId, 'p2');
  });

  test(
    'with notifications off there is no banner and no subscription',
    () async {
      final c = make(notifications: false);
      await c.read(currentProfileProvider.future);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      feed.add(_ann);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(c.read(planBannerProvider), isNull);
      verifyNever(() => plans.announcements(selfId: any(named: 'selfId')));
    },
  );
}
