import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../shared/dashed_border.dart';
import '../../shared/press_effects.dart';
import '../../shared/screen_header.dart';
import '../../shared/staggered_entrance.dart';
import 'plan.dart';
import 'plans_provider.dart';

/// Piani di oggi: più "Ci sono" prima, poi i più recenti. Si aggiorna da solo.
class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(livePlansProvider);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ScreenHeader(
                title: 'Piani di oggi',
                onBack: () =>
                    context.canPop() ? context.pop() : context.go('/home'),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: switch (plans) {
                  AsyncData(:final value) when value.isEmpty =>
                    const _EmptyState(),
                  AsyncData(:final value) => ListView.separated(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: value.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (context, i) => StaggeredEntrance(
                      index: i,
                      child: PlanCard(
                        plan: value[i],
                        onTap: () => context.push('/plans/${value[i].id}'),
                      ),
                    ),
                  ),
                  AsyncError() => _ErrorState(
                    onRetry: () => ref.invalidate(livePlansProvider),
                  ),
                  _ => const Center(child: CircularProgressIndicator()),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card di un piano, nello stile dei pulsanti della Home: colore dell'attività.
class PlanCard extends StatelessWidget {
  const PlanCard({super.key, required this.plan, required this.onTap});

  final Plan plan;
  final VoidCallback onTap;

  static const _radius = 22.0;

  @override
  Widget build(BuildContext context) {
    final a = plan.activity;
    final text = Theme.of(context).textTheme;
    final placeName = plan.place?.name;
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        children: [
          Text(plan.emoji, style: const TextStyle(fontSize: 30)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  placeName == null ? plan.label : '${plan.label} · $placeName',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleMedium?.copyWith(color: a.foreground),
                ),
                const SizedBox(height: 2),
                Text(
                  'di ${plan.creatorNickname} · ${formatTime(plan.createdAt)}',
                  style: text.bodySmall?.copyWith(
                    color: a.foreground.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '🙋 ${plan.count(VoteChoice.yes)}',
                key: const ValueKey('count-yes'),
                style: text.labelLarge?.copyWith(color: a.foreground),
              ),
              Text(
                '😴 ${plan.count(VoteChoice.no)}',
                key: const ValueKey('count-no'),
                style: text.labelLarge?.copyWith(color: a.foreground),
              ),
            ],
          ),
        ],
      ),
    );

    return Semantics(
      button: true,
      child: PressScale(
        scale: 0.97,
        child: GestureDetector(
          key: ValueKey('plan:${plan.id}'),
          onTap: onTap,
          child: a.dashed
              ? CustomPaint(
                  foregroundPainter: DashedBorderPainter(
                    color: a.foreground,
                    radius: _radius,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: a.background,
                      borderRadius: BorderRadius.circular(_radius),
                    ),
                    child: content,
                  ),
                )
              : DecoratedBox(
                  decoration: BoxDecoration(
                    color: a.background,
                    borderRadius: BorderRadius.circular(_radius),
                    boxShadow: [
                      BoxShadow(color: a.shadow, offset: const Offset(0, 5)),
                    ],
                  ),
                  child: content,
                ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🫥', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 12),
          Text(
            'Nessun piano per oggi.',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          SolidPress(
            shadowColor: AppColors.orangeShadow,
            radius: 22,
            child: FilledButton(
              onPressed: () => context.go('/home'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: AppColors.nightBlue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              child: const Text('Lancia il primo? 🚀'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('😵', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 8),
          const Text('Non riesco a caricare i piani.'),
          TextButton(onPressed: onRetry, child: const Text('Riprova')),
        ],
      ),
    );
  }
}
