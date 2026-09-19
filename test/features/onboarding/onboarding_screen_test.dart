import 'package:ciamafa/features/onboarding/onboarding_provider.dart';
import 'package:ciamafa/features/onboarding/onboarding_screen.dart';
import 'package:ciamafa/features/onboarding/profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late MockProfileRepository repo;

  setUp(() {
    repo = MockProfileRepository();
    when(() => repo.fetchCurrentProfile()).thenAnswer((_) async => null);
  });

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    ProviderScope(
      overrides: [profileRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: OnboardingScreen()),
    ),
  );

  FilledButton cta(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byType(FilledButton));

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
}
