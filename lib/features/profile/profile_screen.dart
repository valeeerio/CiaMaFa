import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../shared/press_effects.dart';
import '../../shared/screen_header.dart';
import '../onboarding/onboarding_provider.dart';
import '../onboarding/onboarding_screen.dart'
    show nicknameMaxLength, nicknameMinLength;
import '../onboarding/profile_repository.dart';

/// Profilo: nickname, notifiche, crediti e cancellazione del profilo.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _nickname = TextEditingController(
    text: ref.read(currentProfileProvider).value?.nickname,
  );
  bool _saving = false;
  bool _busy = false;
  String? _nicknameError;

  @override
  void dispose() {
    _nickname.dispose();
    super.dispose();
  }

  String get _current => ref.read(currentProfileProvider).value?.nickname ?? '';

  bool get _canSave {
    final text = _nickname.text.trim();
    return !_saving &&
        text.length >= nicknameMinLength &&
        text.length <= nicknameMaxLength &&
        text != _current;
  }

  void _snack(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  String _failure(Object e) => kDebugMode
      ? 'Ops, qualcosa non va: $e'
      : 'Ops, qualcosa non va. Riprova.';

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _nicknameError = null;
    });
    try {
      await ref.read(profileControllerProvider.notifier).rename(_nickname.text);
      if (!mounted) return;
      _nickname.text = _current;
      _snack('Nickname aggiornato');
    } on NicknameTakenException {
      if (mounted) setState(() => _nicknameError = '😬 Nickname già in uso');
    } catch (e) {
      if (mounted) _snack(_failure(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggleNotifications(bool enabled) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(profileControllerProvider.notifier)
          .setNotifications(enabled);
    } catch (e) {
      if (mounted) _snack(_failure(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteAccount() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancellare il tuo profilo?'),
        content: const Text(
          'Il tuo profilo, i tuoi voti e i tuoi piani ancora attivi verranno '
          'eliminati. Non si può annullare.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancella'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      // Il router porta da solo all'onboarding quando il profilo sparisce.
      await ref.read(profileControllerProvider.notifier).deleteAccount();
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        _snack(_failure(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider).value;
    final text = Theme.of(context).textTheme;
    final nickname = profile?.nickname ?? '';
    final initial = nickname.isEmpty
        ? '?'
        : nickname.characters.first.toUpperCase();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            const ScreenHeader(title: 'Profilo'),
            const SizedBox(height: 24),
            Center(
              child: CircleAvatar(
                radius: 44,
                backgroundColor: AppColors.coral,
                child: Text(
                  initial,
                  style: text.displaySmall?.copyWith(
                    color: AppColors.nightBlue,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(child: Text(nickname, style: text.titleLarge)),
            const SizedBox(height: 28),
            Text('Nickname', style: text.titleSmall),
            const SizedBox(height: 8),
            _Block(
              child: TextField(
                key: const ValueKey('nickname-field'),
                controller: _nickname,
                maxLength: nicknameMaxLength,
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() => _nicknameError = null),
                onSubmitted: (_) => _canSave ? _save() : null,
                style: const TextStyle(
                  color: AppColors.nightBlue,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  errorText: _nicknameError,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SolidPress(
              shadowColor: AppColors.orangeShadow,
              enabled: _canSave,
              radius: 22,
              child: FilledButton(
                key: const ValueKey('save-nickname'),
                onPressed: _canSave ? _save : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: AppColors.nightBlue,
                  disabledBackgroundColor: AppColors.muted,
                  disabledForegroundColor: AppColors.cream,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                child: _saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Salva'),
              ),
            ),
            const SizedBox(height: 28),
            Text('Notifiche', style: text.titleSmall),
            const SizedBox(height: 8),
            _Block(
              child: SwitchListTile(
                key: const ValueKey('notifications-switch'),
                value: profile?.notificationsEnabled ?? true,
                onChanged: _busy || profile == null
                    ? null
                    : _toggleNotifications,
                activeThumbColor: AppColors.nightBlue,
                activeTrackColor: AppColors.acidGreen,
                title: const Text('Avvisami dei piani del gruppo'),
              ),
            ),
            if (profile != null && !profile.notificationsEnabled)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                child: Text(
                  'Non vedrai i piani degli amici.',
                  key: const ValueKey('notifications-off-note'),
                  style: text.bodySmall?.copyWith(color: AppColors.coralText),
                ),
              ),
            const SizedBox(height: 28),
            _Block(
              child: ListTile(
                key: const ValueKey('open-credits'),
                title: const Text('Crediti'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/credits'),
              ),
            ),
            const SizedBox(height: 36),
            Center(
              child: TextButton(
                key: const ValueKey('delete-profile'),
                onPressed: _busy ? null : _deleteAccount,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.coralText,
                ),
                child: const Text('Cancella il mio profilo'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Blocco piatto bianco, raggio 22, ombra piena morbida.
class _Block extends StatelessWidget {
  const _Block({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: Color(0x1F1B2A4A), offset: Offset(0, 4)),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}
