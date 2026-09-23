import 'dart:async';

import 'package:ciamafa/core/constants.dart';
import 'package:ciamafa/core/router.dart';
import 'package:ciamafa/features/onboarding/onboarding_provider.dart';
import 'package:ciamafa/features/onboarding/profile_repository.dart';
import 'package:ciamafa/features/push/device_token_repository.dart';
import 'package:ciamafa/features/push/push_messaging.dart';
import 'package:ciamafa/features/push/push_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockProfiles extends Mock implements ProfileRepository {}

class MockTokens extends Mock implements DeviceTokenRepository {}

class FakePush implements PushMessaging {
  bool available = true;
  bool granted = true;
  String? tokenValue = 'tok-1';
  String? initial;
  int permissionCalls = 0;
  final refreshes = StreamController<String>.broadcast();
  final opened = StreamController<String>.broadcast();

  @override
  bool get isAvailable => available;
  @override
  String get platform => 'ios';
  @override
  Future<bool> requestPermission() async {
    permissionCalls++;
    return granted;
  }

  @override
  Future<String?> token() async => tokenValue;
  @override
  Stream<String> get tokenRefreshes => refreshes.stream;
  @override
  Stream<String> get openedRoutes => opened.stream;
  @override
  Future<String?> initialRoute() async => initial;
}

Profile profile({bool notifications = true, String nickname = 'Valerio'}) =>
    Profile(id: 'me', nickname: nickname, notificationsEnabled: notifications);

void main() {
  late FakePush push;
  late MockTokens tokens;
  late MockProfiles profiles;

  setUp(() {
    push = FakePush();
    tokens = MockTokens();
    profiles = MockProfiles();
    when(
      () => tokens.register(
        token: any(named: 'token'),
        platform: any(named: 'platform'),
      ),
    ).thenAnswer((_) async {});
    when(() => tokens.unregister(any())).thenAnswer((_) async {});
    when(() => profiles.fetchCurrentProfile())
        .thenAnswer((_) async => profile());
  });

  Future<ProviderContainer> make({List<Override> extra = const []}) async {
    final c = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        pushMessagingProvider.overrideWithValue(push),
        deviceTokenRepositoryProvider.overrideWithValue(tokens),
        profileRepositoryProvider.overrideWithValue(profiles),
        ...extra,
      ],
    );
    addTearDown(c.dispose);
    await c.read(currentProfileProvider.future);
    return c;
  }

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 30));

  group('validPushRoute', () {
    test('only our plan routes are accepted', () {
      expect(validPushRoute('/plans'), '/plans');
      expect(validPushRoute('/plans/abc'), '/plans/abc');
      expect(validPushRoute('/profile'), isNull);
      expect(validPushRoute('https://evil.example'), isNull);
      expect(validPushRoute('/plansX'), isNull);
      expect(validPushRoute(null), isNull);
      expect(validPushRoute(42), isNull);
    });
  });

  group('FirebasePushMessaging.optionsFromEnv', () {
    tearDown(() {
      Env.firebaseProjectId = '';
      Env.firebaseSenderId = '';
      Env.firebaseIosApiKey = '';
      Env.firebaseIosAppId = '';
      Env.firebaseAndroidApiKey = '';
      Env.firebaseAndroidAppId = '';
    });

    test('null when Firebase is not configured', () {
      expect(FirebasePushMessaging.optionsFromEnv(TargetPlatform.iOS), isNull);
    });

    test('per-platform keys, and only on iOS/Android', () {
      Env.firebaseProjectId = 'proj';
      Env.firebaseSenderId = '123';
      Env.firebaseIosApiKey = 'ios-key';
      Env.firebaseIosAppId = 'ios-app';
      Env.firebaseAndroidApiKey = 'and-key';
      Env.firebaseAndroidAppId = 'and-app';

      final ios = FirebasePushMessaging.optionsFromEnv(TargetPlatform.iOS)!;
      expect(
        (ios.apiKey, ios.appId, ios.projectId),
        ('ios-key', 'ios-app', 'proj'),
      );
      expect(ios.iosBundleId, 'com.valeriomortella.ciamafa');
      final and = FirebasePushMessaging.optionsFromEnv(TargetPlatform.android)!;
      expect((and.apiKey, and.appId), ('and-key', 'and-app'));
      expect(
        FirebasePushMessaging.optionsFromEnv(TargetPlatform.macOS),
        isNull,
      );
    });

    test('an incomplete config counts as not configured', () {
      Env.firebaseProjectId = 'proj';
      Env.firebaseIosApiKey = 'k';
      expect(FirebasePushMessaging.optionsFromEnv(TargetPlatform.iOS), isNull);
    });
  });

  group('PushController', () {
    test('notifications on: asks permission and registers the token', () async {
      final c = await make();
      c.listen(pushControllerProvider, (_, _) {});
      await settle();

      expect(push.permissionCalls, 1);
      verify(() => tokens.register(token: 'tok-1', platform: 'ios')).called(1);
    });

    test('permission denied: nothing is registered', () async {
      push.granted = false;
      final c = await make();
      c.listen(pushControllerProvider, (_, _) {});
      await settle();

      verifyNever(
        () => tokens.register(
          token: any(named: 'token'),
          platform: any(named: 'platform'),
        ),
      );
    });

    test(
      'no token available (e.g. iPhone without APNs): no crash, no call',
      () async {
        push.tokenValue = null;
        final c = await make();
        c.listen(pushControllerProvider, (_, _) {});
        await settle();

        verifyNever(
          () => tokens.register(
            token: any(named: 'token'),
            platform: any(named: 'platform'),
          ),
        );
      },
    );

    test('token refresh is registered again', () async {
      final c = await make();
      c.listen(pushControllerProvider, (_, _) {});
      await settle();

      push.refreshes.add('tok-2');
      await settle();
      verify(() => tokens.register(token: 'tok-2', platform: 'ios')).called(1);
    });

    test('a failing registration never breaks anything', () async {
      when(
        () => tokens.register(
          token: any(named: 'token'),
          platform: any(named: 'platform'),
        ),
      ).thenThrow(Exception('offline'));
      final c = await make();
      c.listen(pushControllerProvider, (_, _) {});
      await settle(); // nessuna eccezione non gestita
    });

    test('turning notifications off removes the token', () async {
      final c = await make();
      c.listen(pushControllerProvider, (_, _) {});
      await settle();

      c
          .read(currentProfileProvider.notifier)
          .set(profile(notifications: false));
      await settle();
      verify(() => tokens.unregister('tok-1')).called(1);
    });

    test('turning them on again asks again and registers', () async {
      when(() => profiles.fetchCurrentProfile())
          .thenAnswer((_) async => profile(notifications: false));
      final c = await make();
      c.listen(pushControllerProvider, (_, _) {});
      await settle();
      verifyNever(
        () => tokens.register(
          token: any(named: 'token'),
          platform: any(named: 'platform'),
        ),
      );

      c.read(currentProfileProvider.notifier).set(profile());
      await settle();
      verify(() => tokens.register(token: 'tok-1', platform: 'ios')).called(1);
    });

    test('changing the nickname does not register again', () async {
      final c = await make();
      c.listen(pushControllerProvider, (_, _) {});
      await settle();

      c.read(currentProfileProvider.notifier).set(profile(nickname: 'Vale'));
      await settle();
      verify(
        () => tokens.register(
          token: any(named: 'token'),
          platform: any(named: 'platform'),
        ),
      ).called(1);
    });

    test('without Firebase nothing happens', () async {
      push.available = false;
      final c = await make();
      c.listen(pushControllerProvider, (_, _) {});
      await settle();

      expect(push.permissionCalls, 0);
      verifyNever(
        () => tokens.register(
          token: any(named: 'token'),
          platform: any(named: 'platform'),
        ),
      );
    });
  });

  group('PushRouting', () {
    late GoRouter router;

    setUp(() {
      router = GoRouter(
        initialLocation: '/start',
        routes: [
          GoRoute(path: '/start', builder: (_, _) => const SizedBox()),
          GoRoute(path: '/home', builder: (_, _) => const SizedBox()),
          GoRoute(path: '/plans', builder: (_, _) => const SizedBox()),
          GoRoute(path: '/plans/:id', builder: (_, _) => const SizedBox()),
        ],
      );
      addTearDown(router.dispose);
    });

    // L'ultima pagina nello stack (le rotte aperte con push non cambiano `uri`).
    String location() =>
        router.routerDelegate.currentConfiguration.last.matchedLocation;
    int depth() => router.routerDelegate.currentConfiguration.matches.length;

    // Il router si avvia solo quando è collegato a un albero di widget.
    Future<ProviderContainer> makeRouted(WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      final c = await make(extra: [routerProvider.overrideWithValue(router)]);
      c.listen(pushRoutingProvider, (_, _) {});
      await tester.pumpAndSettle();
      return c;
    }

    testWidgets(
      'tapping a notification while the app is open opens that plan',
      (tester) async {
        await makeRouted(tester);

        push.opened.add('/plans/p1');
        await tester.pump(const Duration(milliseconds: 50));
        expect(location(), '/plans/p1');
      },
    );

    testWidgets(
      'a notification that started the app opens Home, then the plan',
      (tester) async {
        push.initial = '/plans/p9';
        await makeRouted(tester);

        expect(location(), '/plans/p9');
        expect(depth(), 2); // Home sotto: "indietro" torna alla Home
      },
    );

    testWidgets('no profile yet: the launch notification is ignored', (
      tester,
    ) async {
      when(() => profiles.fetchCurrentProfile()).thenAnswer((_) async => null);
      push.initial = '/plans/p9';
      await makeRouted(tester);

      expect(location(), '/start');
    });

    testWidgets('nothing to open, nothing happens', (tester) async {
      await makeRouted(tester);
      expect(location(), '/start');
    });
  });
}
