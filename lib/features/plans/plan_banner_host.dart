import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/motion.dart';
import '../../core/router.dart';
import '../../shared/notification_banner.dart';
import 'plans_provider.dart';

/// Sopra a tutte le schermate: mostra il banner "nuovo piano" degli amici.
class PlanBannerHost extends ConsumerWidget {
  const PlanBannerHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcement = ref.watch(planBannerProvider);
    return Stack(
      children: [
        child,
        Positioned(
          left: 16,
          right: 16,
          top: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: AnimatedSwitcher(
                duration: Motion.of(context, Motion.base),
                switchInCurve: Motion.soft,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0, -0.6),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: announcement == null
                    ? const SizedBox.shrink(key: ValueKey('no-banner'))
                    : Material(
                        key: ValueKey(announcement.planId),
                        type: MaterialType.transparency,
                        child: NotificationBanner(
                          title: announcement.title,
                          subtitle: announcement.subtitle,
                          onTap: () {
                            ref.read(planBannerProvider.notifier).dismiss();
                            ref
                                .read(routerProvider)
                                .push(
                                  announcement.cancelled
                                      ? '/plans'
                                      : '/plans/${announcement.planId}',
                                );
                          },
                          onClose: () =>
                              ref.read(planBannerProvider.notifier).dismiss(),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
