import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../shared/activity_button.dart';
import '../onboarding/onboarding_provider.dart';
import '../plans/activity.dart';
import '../plans/plans_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nickname = ref.watch(currentProfileProvider).value?.nickname ?? '';
    final initial = nickname.isEmpty
        ? '?'
        : nickname.characters.first.toUpperCase();
    final plansToday = ref.watch(livePlansProvider).value?.length ?? 0;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            Row(
              children: [
                Semantics(
                  button: true,
                  label: 'Profilo',
                  child: GestureDetector(
                    onTap: () => context.push('/profile'),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.coral,
                      child: Text(
                        initial,
                        style: text.titleLarge?.copyWith(
                          color: AppColors.nightBlue,
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () => context.push('/plans'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.nightBlue,
                    foregroundColor: AppColors.cream,
                    shape: const StadiumBorder(),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('📅 Impegni'),
                      // Quanti piani ci sono oggi (si aggiorna in tempo reale).
                      if (plansToday > 0) ...[
                        const SizedBox(width: 8),
                        CircleAvatar(
                          key: const ValueKey('plans-badge'),
                          radius: 11,
                          backgroundColor: AppColors.coral,
                          child: Text(
                            '$plansToday',
                            style: const TextStyle(
                              color: AppColors.nightBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text('CiaMaFa?', style: text.displayLarge),
            Text(
              'Lancia un piano al gruppo.',
              style: text.titleMedium?.copyWith(color: AppColors.coralText),
            ),
            const SizedBox(height: 28),
            for (final activity in activities) ...[
              ActivityButton(
                activity: activity,
                onTap: (origin) =>
                    context.push('/places/${activity.id}', extra: origin),
              ),
              const SizedBox(height: 18),
            ],
          ],
        ),
      ),
    );
  }
}
