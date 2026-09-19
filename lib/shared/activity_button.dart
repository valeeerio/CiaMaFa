import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../features/plans/activity.dart';
import 'dashed_border.dart';

/// Pulsante grande di un'attività nella Home.
class ActivityButton extends StatelessWidget {
  const ActivityButton({
    super.key,
    required this.activity,
    required this.onTap,
  });

  final Activity activity;
  final VoidCallback onTap;

  static const _radius = 22.0;

  @override
  Widget build(BuildContext context) {
    final a = activity;
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      child: Row(
        children: [
          Text(a.emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              a.label,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(color: a.foreground, fontSize: a.dashed ? 18 : 22),
            ),
          ),
        ],
      ),
    );

    final button = Semantics(
      button: true,
      label: a.label,
      child: GestureDetector(
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
    );

    return a.dashed
        ? Transform.rotate(angle: -math.pi / 180, child: button)
        : button;
  }
}
