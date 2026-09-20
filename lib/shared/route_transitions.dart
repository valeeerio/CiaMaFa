import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/motion.dart';

/// Da dove parte l'espansione: rettangolo (in coordinate globali), colore e
/// raggio del pulsante toccato.
class TransitionOrigin {
  const TransitionOrigin({
    required this.rect,
    required this.color,
    required this.radius,
  });

  final Rect rect;
  final Color color;
  final double radius;
}

/// Pagina che si apre espandendo il pulsante di origine fino a riempire lo
/// schermo; in chiusura si richiude sul pulsante. Senza [origin], o con
/// "Riduci movimento", è una semplice dissolvenza.
CustomTransitionPage<void> expandingPage({
  required LocalKey key,
  required Widget child,
  TransitionOrigin? origin,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: Motion.slow,
    reverseTransitionDuration: Motion.base,
    transitionsBuilder: (context, animation, secondaryAnimation, page) {
      if (origin == null || Motion.reduced(context)) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: page,
        );
      }
      return LayoutBuilder(
        builder: (context, constraints) {
          final full = Offset.zero & constraints.biggest;
          return AnimatedBuilder(
            animation: animation,
            child: page,
            builder: (context, page) {
              final t = Motion.emphasized.transform(animation.value);
              final rect = Rect.lerp(origin.rect, full, t)!;
              final radius = lerpDouble(origin.radius, 0, t)!;
              final pageOpacity = const Interval(
                0.5,
                1,
                curve: Curves.easeOut,
              ).transform(animation.value);
              return Stack(
                children: [
                  Positioned.fromRect(
                    rect: rect,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: origin.color,
                        borderRadius: BorderRadius.circular(radius),
                      ),
                    ),
                  ),
                  Opacity(opacity: pageOpacity, child: page),
                ],
              );
            },
          );
        },
      );
    },
  );
}
