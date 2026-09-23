import 'package:ciamafa/features/onboarding/onboarding_provider.dart';
import 'package:ciamafa/features/onboarding/onboarding_screen.dart';
import 'package:ciamafa/features/onboarding/profile_repository.dart';
import 'package:ciamafa/features/onboarding/social_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockSocialAuth extends Mock implements SocialAuthService {}

void main() {
  late MockProfileRepository repo;
  late MockSocialAuth social;

  setUpAll(() => registerFallbackValue(SocialProvider.apple));

  setUp(() {
    repo = MockProfileRepository();
    social = MockSocialAuth();
    when(() => repo.fetchCurrentProfile()).thenAnswer((_) async => null);
  });

  Future<void> pump(WidgetTester tester, {bool signedIn = true}) {
    when(() => repo.isSignedIn).thenReturn(signedIn);
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileRepositoryProvider.overrideWithValue(repo),
          socialAuthServiceProvider.overrideWithValue(social),
        ],
        child: const MaterialApp(home: OnboardingScreen()),
      ),
    );
  }

  FilledButton cta(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byType(FilledButton));

  group('nickname step (già passato da Apple/Google)', () {
    testWidgets('CTA disabled until nickname is valid', (tester) async {
      await pump(tester);
      expect(cta(tester).onPressed, isNull);

      await tester.enterText(find.byType(TextField), 'V');
      await tester.pump();
      expect(cta(tester).onPressed, isNull);

      await tester.enterText(find.byType(TextField), 'Valerio');
      await tester.pump();
      expect(cta(tester).onPressed, isNotNull);
    });

    testWidgets('shows "Nickname già in uso" when nickname is taken', (
      tester,
    ) async {
      when(
        () => repo.joinGroup(
          nickname: any(named: 'nickname'),
          notificationsEnabled: any(named: 'notificationsEnabled'),
        ),
      ).thenThrow(const NicknameTakenException());
      await pump(tester);

      await tester.enterText(find.byType(TextField), 'Marta');
      await tester.pump();
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.text('😬 Nickname già in uso'), findsOneWidget);
    });
  });

  group('sign-in step (senza sessione)', () {
    testWidgets('shows Apple and Google, no nickname field yet', (
      tester,
    ) async {
      await pump(tester, signedIn: false);
      expect(find.byKey(const ValueKey('sign-in-apple')), findsOneWidget);
      expect(find.byKey(const ValueKey('sign-in-google')), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('Apple succeeds: moves on to the nickname step', (
      tester,
    ) async {
      when(() => social.signIn(SocialProvider.apple)).thenAnswer((_) async {});
      await pump(tester, signedIn: false);

      await tester.tap(find.byKey(const ValueKey('sign-in-apple')));
      await tester.pumpAndSettle();

      verify(() => social.signIn(SocialProvider.apple)).called(1);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byKey(const ValueKey('sign-in-apple')), findsNothing);
    });

    testWidgets('cancelling stays on this step, no error shown', (
      tester,
    ) async {
      when(() => social.signIn(SocialProvider.google))
          .thenThrow(const SocialSignInCancelled());
      await pump(tester, signedIn: false);

      await tester.tap(find.byKey(const ValueKey('sign-in-google')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('sign-in-google')), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.textContaining('Ops'), findsNothing);
    });

    testWidgets('a real failure is reported and the buttons work again', (
      tester,
    ) async {
      when(() => social.signIn(SocialProvider.apple))
          .thenThrow(Exception('offline'));
      await pump(tester, signedIn: false);

      await tester.tap(find.byKey(const ValueKey('sign-in-apple')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Ops, qualcosa non va'), findsOneWidget);
      final button = tester.widget<FilledButton>(
        find.descendant(
          of: find.byKey(const ValueKey('sign-in-apple')),
          matching: find.byType(FilledButton),
        ),
      );
      expect(button.onPressed, isNotNull);
    });
  });
}
