import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'image_picker_service.dart';

/// Piccolo sheet "Scatta / Galleria". Restituisce la scelta, `null` se chiuso.
Future<PickSource?> showImageSourceSheet(BuildContext context) {
  return showModalBottomSheet<PickSource>(
    context: context,
    backgroundColor: AppColors.cream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Option(
              emoji: '📸',
              label: 'Scatta',
              onTap: () => Navigator.pop(context, PickSource.camera),
            ),
            const SizedBox(height: 12),
            _Option(
              emoji: '🖼️',
              label: 'Galleria',
              onTap: () => Navigator.pop(context, PickSource.gallery),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Option extends StatelessWidget {
  const _Option({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.nightBlue,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      child: Text('$emoji  $label'),
    );
  }
}
