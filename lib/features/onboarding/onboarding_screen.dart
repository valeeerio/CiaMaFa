import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import 'onboarding_provider.dart';
import 'profile_repository.dart';
import 'social_auth_service.dart';

const nicknameMinLength = 2;
const nicknameMaxLength = 20;

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = TextEditingController();
  bool _notifications = true;

  /// Già passato da Apple/Google: si passa allo step del nickname. Letto una
  /// volta sola all'avvio (se l'app riparte a metà flusso, un nuovo tocco su
  /// Apple/Google è innocuo).
  late bool _authenticated = ref.read(profileRepositoryProvider).isSignedIn;
  bool _signingIn = false;
  String? _signInError;

  bool get _valid {
    final n = _controller.text.trim().length;
    return n >= nicknameMinLength && n <= nicknameMaxLength;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _failure(Object e) => kDebugMode
      ? 'Ops, qualcosa non va: $e'
      : 'Ops, qualcosa non va. Riprova.';

  Future<void> _signIn(SocialProvider provider) async {
    setState(() {
      _signingIn = true;
      _signInError = null;
    });
    try {
      await ref.read(socialAuthServiceProvider).signIn(provider);
      if (mounted) setState(() => _authenticated = true);
    } on SocialSignInCancelled {
      // Ha chiuso il foglio di Apple/Google: nessun errore da mostrare.
    } catch (e) {
      if (mounted) setState(() => _signInError = _failure(e));
    } finally {
      if (mounted) setState(() => _signingIn = false);
    }
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    ref
        .read(onboardingControllerProvider.notifier)
        .submit(
          nickname: _controller.text,
          notificationsEnabled: _notifications,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.nightBlue,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.acidGreen,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Text('🙌', style: TextStyle(fontSize: 44)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'CiaMaFa',
                textAlign: TextAlign.center,
                style: theme.displayMedium?.copyWith(color: AppColors.cream),
              ),
              Text(
                'Che si fa stasera?',
                textAlign: TextAlign.center,
                style: theme.titleMedium?.copyWith(color: AppColors.acidGreen),
              ),
              const SizedBox(height: 40),
              if (_authenticated)
                _NicknameStep(
                  controller: _controller,
                  notifications: _notifications,
                  valid: _valid,
                  onChanged: () => setState(() {}),
                  onNotificationsChanged: (v) =>
                      setState(() => _notifications = v),
                  onSubmit: _submit,
                )
              else
                _SignInStep(
                  signingIn: _signingIn,
                  error: _signInError,
                  onTap: _signIn,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Step 1: scegli come accedere. Nessuna email da digitare.
class _SignInStep extends StatelessWidget {
  const _SignInStep({
    required this.signingIn,
    required this.error,
    required this.onTap,
  });

  final bool signingIn;
  final String? error;
  final ValueChanged<SocialProvider> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Come vuoi accedere?',
          textAlign: TextAlign.center,
          style: theme.labelLarge?.copyWith(color: AppColors.cream),
        ),
        const SizedBox(height: 16),
        _SocialButton(
          key: const ValueKey('sign-in-apple'),
          label: 'Accedi con Apple',
          icon: Icons.apple,
          background: AppColors.cream,
          foreground: AppColors.nightBlue,
          enabled: !signingIn,
          onTap: () => onTap(SocialProvider.apple),
        ),
        const SizedBox(height: 12),
        _SocialButton(
          key: const ValueKey('sign-in-google'),
          label: 'Accedi con Google',
          icon: Icons.g_mobiledata,
          background: AppColors.acidGreen,
          foreground: AppColors.nightBlue,
          enabled: !signingIn,
          onTap: () => onTap(SocialProvider.google),
        ),
        if (signingIn) ...[
          const SizedBox(height: 16),
          const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.cream,
              ),
            ),
          ),
        ],
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(
            error!,
            textAlign: TextAlign.center,
            style: theme.bodySmall?.copyWith(color: AppColors.coral),
          ),
        ],
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    super.key,
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: enabled ? onTap : null,
      icon: Icon(icon, color: foreground),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        disabledBackgroundColor: AppColors.muted,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}

/// Step 2: nickname e notifiche, come sempre.
class _NicknameStep extends ConsumerWidget {
  const _NicknameStep({
    required this.controller,
    required this.notifications,
    required this.valid,
    required this.onChanged,
    required this.onNotificationsChanged,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool notifications;
  final bool valid;
  final VoidCallback onChanged;
  final ValueChanged<bool> onNotificationsChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final loading = state.isLoading;
    final error = state.hasError ? state.error : null;
    final errorText = switch (error) {
      null => null,
      NicknameTakenException() => '😬 Nickname già in uso',
      _ =>
        kDebugMode
            ? 'Ops, qualcosa non va: $error'
            : 'Ops, qualcosa non va. Riprova.',
    };
    final theme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Come ti chiami?',
          style: theme.labelLarge?.copyWith(color: AppColors.cream),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: !loading,
          maxLength: nicknameMaxLength,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          onChanged: (_) => onChanged(),
          onSubmitted: (_) => valid && !loading ? onSubmit() : null,
          style: const TextStyle(color: AppColors.nightBlue),
          decoration: InputDecoration(
            hintText: 'Il tuo nickname',
            counterText: '',
            errorText: errorText,
            errorStyle: const TextStyle(color: AppColors.coral),
            filled: true,
            fillColor: AppColors.cream,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          value: notifications,
          onChanged: loading ? null : onNotificationsChanged,
          activeThumbColor: AppColors.nightBlue,
          activeTrackColor: AppColors.acidGreen,
          contentPadding: EdgeInsets.zero,
          title: Text(
            '🔔 Notifiche',
            style: theme.titleSmall?.copyWith(color: AppColors.cream),
          ),
          subtitle: Text(
            'Ti avvisiamo quando qualcuno lancia un piano.',
            style: theme.bodySmall?.copyWith(color: AppColors.cream),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: valid && !loading ? onSubmit : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.orange,
            foregroundColor: AppColors.nightBlue,
            disabledBackgroundColor: AppColors.muted,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text(
                  'Entra nel gruppo 🎉',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
        ),
      ],
    );
  }
}
