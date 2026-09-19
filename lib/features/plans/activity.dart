import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Attività fisse dell'app (ordine e colori dal design reference).
class Activity {
  const Activity({
    required this.id,
    required this.emoji,
    required this.label,
    required this.background,
    required this.foreground,
    required this.shadow,
    this.dashed = false,
  });

  final String id;
  final String emoji;
  final String label;
  final Color background;
  final Color foreground;
  final Color shadow;

  /// Solo "Bho, vediamoci e decidiamo": bordo tratteggiato, senza ombra piena.
  final bool dashed;
}

const activities = <Activity>[
  Activity(
    id: 'bar',
    emoji: '🍻',
    label: 'Bar',
    background: AppColors.orange,
    foreground: AppColors.nightBlue,
    shadow: AppColors.orangeShadow,
  ),
  Activity(
    id: 'bombolone',
    emoji: '🍁',
    label: 'Bombolone',
    background: AppColors.coral,
    foreground: AppColors.nightBlue,
    shadow: AppColors.coralShadow,
  ),
  Activity(
    id: 'chill',
    emoji: '🛋️',
    label: 'Posto Chill',
    background: AppColors.nightBlue,
    foreground: AppColors.cream,
    shadow: AppColors.nightBlue,
  ),
  Activity(
    id: 'mangiare',
    emoji: '🍽️',
    label: 'Mangiare',
    background: AppColors.acidGreen,
    foreground: AppColors.nightBlue,
    shadow: AppColors.acidGreenShadow,
  ),
  Activity(
    id: 'bho',
    emoji: '🎲',
    label: 'Bho, vediamoci e decidiamo',
    background: AppColors.cream,
    foreground: AppColors.nightBlue,
    shadow: AppColors.nightBlue,
    dashed: true,
  ),
];

Activity activityById(String id) =>
    activities.firstWhere((a) => a.id == id, orElse: () => activities.last);
