import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import 'onboarding_provider.dart';
import 'profile_repository.dart';

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

  bool get _valid {
    final n = _controller.text.trim().length;
    return n >= nicknameMinLength && n <= nicknameMaxLength;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
              Text(
                'Come ti chiami?',
                style: theme.labelLarge?.copyWith(color: AppColors.cream),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                enabled: !loading,
                maxLength: nicknameMaxLength,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _valid && !loading ? _submit() : null,
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
                value: _notifications,
                onChanged: loading
                    ? null
                    : (v) => setState(() => _notifications = v),
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
                onPressed: _valid && !loading ? _submit : null,
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
