import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/supabase_client.dart';
import 'profile_repository.dart';
import 'social_auth_service.dart';

part 'onboarding_provider.g.dart';

@Riverpod(keepAlive: true)
ProfileRepository profileRepository(Ref ref) =>
    SupabaseProfileRepository(supabase);

@Riverpod(keepAlive: true)
SocialAuthService socialAuthService(Ref ref) =>
    SupabaseSocialAuthService(supabase);

/// Profilo dell'utente corrente (`null` se deve ancora fare l'onboarding).
@Riverpod(keepAlive: true)
class CurrentProfile extends _$CurrentProfile {
  @override
  Future<Profile?> build() =>
      ref.watch(profileRepositoryProvider).fetchCurrentProfile();

  void set(Profile profile) => state = AsyncData(profile);

  /// Dopo la cancellazione del profilo: si torna all'onboarding.
  void clear() => state = const AsyncData(null);
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
      final profile = await ref
          .read(profileRepositoryProvider)
          .joinGroup(
            nickname: nickname.trim(),
            notificationsEnabled: notificationsEnabled,
          );
      ref.read(currentProfileProvider.notifier).set(profile);
    });
  }
}

/// Azioni del Profilo. Gli errori arrivano alla schermata (es. nickname in uso).
/// keepAlive: le azioni terminano anche se nessuno ascolta (niente dispose a metà).
@Riverpod(keepAlive: true)
class ProfileController extends _$ProfileController {
  @override
  void build() {}

  Future<void> rename(String nickname) async {
    final profile = await ref
        .read(profileRepositoryProvider)
        .updateNickname(nickname);
    ref.read(currentProfileProvider.notifier).set(profile);
  }

  Future<void> setNotifications(bool enabled) async {
    final profile = await ref
        .read(profileRepositoryProvider)
        .setNotificationsEnabled(enabled);
    ref.read(currentProfileProvider.notifier).set(profile);
  }

  Future<void> deleteAccount() async {
    await ref.read(profileRepositoryProvider).deleteProfile();
    ref.read(currentProfileProvider.notifier).clear();
  }
}
