import 'package:flutter/material.dart';

import '../core/motion.dart';
import '../core/theme.dart';
import 'press_effects.dart';

/// Barra di navigazione fissa delle 4 schermate principali.
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.plansCount = 0,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Piani di oggi: badge sull'icona "Piani" (nascosto a zero).
  final int plansCount;

  static const height = 78.0;
  static const _items = [
    ('🏠', 'Home'),
    ('📅', 'Piani'),
    ('💬', 'Chat'),
    ('🙂', 'Profilo'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x141B2A4A),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SizedBox(
          height: height,
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: _NavItem(
                    emoji: _items[i].$1,
                    label: _items[i].$2,
                    selected: i == currentIndex,
                    badge: i == 1 ? plansCount : 0,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.badge,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool selected;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final color = selected ? AppColors.nightBlue : AppColors.muted;
    return Semantics(
      button: true,
      selected: selected,
      label: badge > 0 ? '$label, $badge piani di oggi' : label,
      excludeSemantics: true,
      child: PressScale(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Le emoji non si colorano: l'inattiva si attenua.
                  AnimatedOpacity(
                    opacity: selected ? 1 : 0.55,
                    duration: Motion.of(context, Motion.fast),
                    curve: Motion.soft,
                    child: Text(emoji, style: const TextStyle(fontSize: 24)),
                  ),
                  if (badge > 0)
                    Positioned(
                      top: -6,
                      right: -12,
                      child: CircleAvatar(
                        key: const ValueKey('plans-badge'),
                        radius: 9,
                        backgroundColor: AppColors.acidGreen,
                        child: Text(
                          '$badge',
                          style: const TextStyle(
                            color: AppColors.nightBlue,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: text.labelMedium?.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
