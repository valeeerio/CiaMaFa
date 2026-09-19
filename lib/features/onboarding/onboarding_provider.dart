import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/supabase_client.dart';
import 'profile_repository.dart';

part 'onboarding_provider.g.dart';

@Riverpod(keepAlive: true)
ProfileRepository profileRepository(Ref ref) =>
    SupabaseProfileRepository(supabase);

/// Profilo dell'utente corrente (`null` se deve ancora fare l'onboarding).
@Riverpod(keepAlive: true)
class CurrentProfile extends _$CurrentProfile {
  @override
  Future<Profile?> build() =>
      ref.watch(profileRepositoryProvider).fetchCurrentProfile();

  void set(Profile profile) => state = AsyncData(profile);
}

@riverpod
class OnboardingController extends _$OnboardingController {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> submit({
    required String nickname,
    required bool notificationsEnabled,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final profile = await ref.read(profileRepositoryProvider).joinGroup(
            nickname: nickname.trim(),
            notificationsEnabled: notificationsEnabled,
          );
      ref.read(currentProfileProvider.notifier).set(profile);
    });
  }
}
