import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'press_effects.dart';

/// Banner di notifica in alto: blu notte semitrasparente, tap apre, ✕ chiude.
class NotificationBanner extends StatelessWidget {
  const NotificationBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.onClose,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      container: true,
      child: PressScale(
        scale: 0.98,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.nightBlue.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(color: Color(0x40000000), offset: Offset(0, 4)),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 6, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.cream,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.cream.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Chiudi',
                    onPressed: onClose,
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.cream,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
