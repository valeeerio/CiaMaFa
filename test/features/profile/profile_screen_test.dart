import 'package:ciamafa/core/theme.dart';
import 'package:ciamafa/features/onboarding/onboarding_provider.dart';
import 'package:ciamafa/features/onboarding/profile_repository.dart';
import 'package:ciamafa/features/profile/credits_screen.dart';
import 'package:ciamafa/features/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockProfiles extends Mock implements ProfileRepository {}

const _me = Profile(id: 'me', nickname: 'Valerio', notificationsEnabled: true);

void main() {
  late MockProfiles repo;
  late GoRouter router;

  setUp(() {
    repo = MockProfiles();
    when(() => repo.fetchCurrentProfile()).thenAnswer((_) async => _me);
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    router = GoRouter(
      initialLocation: '/profile',
      routes: [
        GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
        GoRoute(path: '/credits', builder: (_, _) => const Text('CREDITI')),
        GoRoute(
          path: '/onboarding',
          builder: (_, _) => const Scaffold(body: Text('ONBOARDING')),
        ),
      ],
      // Come l'app: senza profilo si va all'onboarding.
      redirect: (context, state) {
        final container = ProviderScope.containerOf(context);
        final profile = container.read(currentProfileProvider);
        if (profile.isLoading) return null;
        final hasProfile = profile.value != null;
        return !hasProfile && state.matchedLocation != '/onboarding'
            ? '/onboarding'
            : null;
      },
    );
    addTearDown(router.dispose);
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [profileRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    await container.read(currentProfileProvider.future); // come nell'app
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Consumer(
          builder: (context, ref, _) {
            // Riesegue il redirect quando il profilo cambia (fa il router dell'app).
            ref.listen(currentProfileProvider, (_, _) => router.refresh());
            return MaterialApp.router(routerConfig: router);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder field() => find.byKey(const ValueKey('nickname-field'));
  FilledButton save(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byKey(const ValueKey('save-nickname')));

  group('nickname', () {
    testWidgets('shows avatar initial and current nickname', (tester) async {
      await pump(tester);
      expect(find.text('V'), findsOneWidget);
      expect(find.text('Valerio'), findsWidgets);
      expect(tester.widget<TextField>(field()).controller!.text, 'Valerio');
    });

    testWidgets('Salva is off until the nickname changes and is valid', (
      tester,
    ) async {
      await pump(tester);
      expect(save(tester).onPressed, isNull); // invariato

      await tester.enterText(field(), 'V'); // troppo corto
      await tester.pump();
      expect(save(tester).onPressed, isNull);

      await tester.enterText(field(), 'Vale');
      await tester.pump();
      expect(save(tester).onPressed, isNotNull);

      await tester.enterText(
        field(),
        '  Valerio  ',
      ); // stesso nome, spazi a parte
      await tester.pump();
      expect(save(tester).onPressed, isNull);
    });

    testWidgets('saving updates the profile and says so', (tester) async {
      when(() => repo.updateNickname(any())).thenAnswer(
        (_) async => const Profile(
          id: 'me',
          nickname: 'Vale',
          notificationsEnabled: true,
        ),
      );
      await pump(tester);
      await tester.enterText(field(), 'Vale');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('save-nickname')));
      await tester.pumpAndSettle();

      verify(() => repo.updateNickname('Vale')).called(1);
      expect(find.text('Nickname aggiornato'), findsOneWidget);
      expect(find.text('V'), findsOneWidget);
      expect(save(tester).onPressed, isNull); // ora coincide
    });

    testWidgets('a taken nickname shows the error, and typing clears it', (
      tester,
    ) async {
      when(() => repo.updateNickname(any()))
          .thenThrow(const NicknameTakenException());
      await pump(tester);
      await tester.enterText(field(), 'Anna');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('save-nickname')));
      await tester.pumpAndSettle();
      expect(find.text('😬 Nickname già in uso'), findsOneWidget);

      await tester.enterText(field(), 'Anna2');
      await tester.pump();
      expect(find.text('😬 Nickname già in uso'), findsNothing);
    });

    testWidgets('another failure is reported without losing the text', (
      tester,
    ) async {
      when(() => repo.updateNickname(any())).thenThrow(Exception('offline'));
      await pump(tester);
      await tester.enterText(field(), 'Anna');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('save-nickname')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Ops, qualcosa non va'), findsOneWidget);
      expect(tester.widget<TextField>(field()).controller!.text, 'Anna');
    });
  });

  group('notifiche', () {
    Switch sw(WidgetTester tester) => tester.widget<Switch>(
      find.descendant(
        of: find.byKey(const ValueKey('notifications-switch')),
        matching: find.byType(Switch),
      ),
    );

    testWidgets('on by default, no warning note', (tester) async {
      await pump(tester);
      expect(sw(tester).value, isTrue);
      expect(
        find.byKey(const ValueKey('notifications-off-note')),
        findsNothing,
      );
    });

    testWidgets('turning off saves and shows the note', (tester) async {
      when(() => repo.setNotificationsEnabled(false)).thenAnswer(
        (_) async => const Profile(
          id: 'me',
          nickname: 'Valerio',
          notificationsEnabled: false,
        ),
      );
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey('notifications-switch')));
      await tester.pumpAndSettle();

      verify(() => repo.setNotificationsEnabled(false)).called(1);
      expect(sw(tester).value, isFalse);
      expect(find.text('Non vedrai i piani degli amici.'), findsOneWidget);
    });

    testWidgets('a failure keeps the switch as it was and says so', (
      tester,
    ) async {
      when(() => repo.setNotificationsEnabled(any()))
          .thenThrow(Exception('offline'));
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey('notifications-switch')));
      await tester.pumpAndSettle();

      expect(sw(tester).value, isTrue);
      expect(find.textContaining('Ops, qualcosa non va'), findsOneWidget);
    });
  });

  group('crediti e cancellazione', () {
    testWidgets('"Crediti" opens the credits page', (tester) async {
      await pump(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('open-credits')));
      await tester.tap(find.byKey(const ValueKey('open-credits')));
      await tester.pumpAndSettle();
      expect(find.text('CREDITI'), findsOneWidget);
    });

    testWidgets('delete asks first; "Annulla" keeps everything', (
      tester,
    ) async {
      await pump(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('delete-profile')));
      await tester.tap(find.byKey(const ValueKey('delete-profile')));
      await tester.pumpAndSettle();
      expect(find.text('Cancellare il tuo profilo?'), findsOneWidget);

      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();
      verifyNever(() => repo.deleteProfile());
      expect(find.text('Profilo'), findsOneWidget);
    });

    testWidgets('confirming deletes the profile and goes to onboarding', (
      tester,
    ) async {
      when(() => repo.deleteProfile()).thenAnswer((_) async {});
      await pump(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('delete-profile')));
      await tester.tap(find.byKey(const ValueKey('delete-profile')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancella'));
      await tester.pumpAndSettle();

      verify(() => repo.deleteProfile()).called(1);
      expect(find.text('ONBOARDING'), findsOneWidget);
    });

    testWidgets('a failed deletion stays here and says so', (tester) async {
      when(() => repo.deleteProfile()).thenThrow(Exception('offline'));
      await pump(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('delete-profile')));
      await tester.tap(find.byKey(const ValueKey('delete-profile')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancella'));
      await tester.pumpAndSettle();

      expect(find.text('ONBOARDING'), findsNothing);
      expect(find.textContaining('Ops, qualcosa non va'), findsOneWidget);
      // …e si può riprovare.
      expect(
        tester
            .widget<TextButton>(find.byKey(const ValueKey('delete-profile')))
            .onPressed,
        isNotNull,
      );
    });
  });

  group('Crediti', () {
    Future<void> pumpCredits(
      WidgetTester tester, {
      String version = '1.2.3 (45)',
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appVersionProvider.overrideWith((ref) async => version)],
          child: const MaterialApp(home: CreditsScreen()),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('map and search attributions, licenses and version', (
      tester,
    ) async {
      await pumpCredits(tester);
      expect(
        find.text('© OpenStreetMap contributors · © CARTO'),
        findsOneWidget,
      );
      expect(
        find.text('Photon by Komoot · dati © OpenStreetMap contributors'),
        findsOneWidget,
      );
      expect(find.text('Licenze open source'), findsOneWidget);
      expect(find.text('CiaMaFa 1.2.3 (45)'), findsOneWidget);
    });

    testWidgets('"Licenze open source" opens the Flutter licenses page', (
      tester,
    ) async {
      await pumpCredits(tester);
      await tester.tap(find.byKey(const ValueKey('open-licenses')));
      await tester.pumpAndSettle();
      expect(find.byType(LicensePage), findsOneWidget);
    });
  });

  test('palette untouched: coral text colour used for destructive actions', () {
    expect(AppColors.coralText, const Color(0xFFB33B30));
  });
}
