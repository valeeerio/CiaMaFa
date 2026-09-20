import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'press_effects.dart';

/// Testata simmetrica: freccia a sinistra, [title] al centro, spazio vuoto a
/// destra della stessa larghezza della freccia.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  static const _side = 44.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Semantics(
          button: true,
          label: 'Indietro',
          child: PressScale(
            child: GestureDetector(
              onTap: onBack,
              behavior: HitTestBehavior.opaque,
              child: const CircleAvatar(
                radius: _side / 2,
                backgroundColor: AppColors.nightBlue,
                child: Icon(Icons.arrow_back, color: AppColors.cream, size: 20),
              ),
            ),
          ),
        ),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ),
        ),
        const SizedBox(width: _side),
      ],
    );
  }
}
