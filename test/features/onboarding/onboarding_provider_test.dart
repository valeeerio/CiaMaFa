import 'package:ciamafa/features/onboarding/onboarding_provider.dart';
import 'package:ciamafa/features/onboarding/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

const _profile =
    Profile(id: 'u1', nickname: 'Valerio', notificationsEnabled: true);

void main() {
  late MockProfileRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = MockProfileRepository();
    when(() => repo.fetchCurrentProfile()).thenAnswer((_) async => null);
    container = ProviderContainer(
      overrides: [profileRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
  });

  Future<void> submit() => container
      .read(onboardingControllerProvider.notifier)
      .submit(nickname: '  Valerio ', notificationsEnabled: true);

  test('success: joins with trimmed nickname and stores the profile', () async {
    when(() => repo.joinGroup(
          nickname: any(named: 'nickname'),
          notificationsEnabled: any(named: 'notificationsEnabled'),
        )).thenAnswer((_) async => _profile);
    await container.read(currentProfileProvider.future);

    await submit();

    verify(() => repo.joinGroup(nickname: 'Valerio', notificationsEnabled: true))
        .called(1);
    expect(container.read(onboardingControllerProvider).hasError, isFalse);
    expect(container.read(currentProfileProvider).value?.nickname, 'Valerio');
  });

  test('nickname taken: exposes NicknameTakenException, no profile', () async {
    when(() => repo.joinGroup(
          nickname: any(named: 'nickname'),
          notificationsEnabled: any(named: 'notificationsEnabled'),
        )).thenThrow(const NicknameTakenException());
    await container.read(currentProfileProvider.future);

    await submit();

    expect(container.read(onboardingControllerProvider).error,
        isA<NicknameTakenException>());
    expect(container.read(currentProfileProvider).value, isNull);
  });

  test('network error: exposes the error, no profile', () async {
    when(() => repo.joinGroup(
          nickname: any(named: 'nickname'),
          notificationsEnabled: any(named: 'notificationsEnabled'),
        )).thenThrow(Exception('offline'));
    await container.read(currentProfileProvider.future);

    await submit();

    expect(container.read(onboardingControllerProvider).hasError, isTrue);
    expect(container.read(currentProfileProvider).value, isNull);
  });
}
