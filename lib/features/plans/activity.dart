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
    required this.launchCta,
    this.dashed = false,
  });

  final String id;
  final String emoji;
  final String label;
  final Color background;
  final Color foreground;
  final Color shadow;

  /// Testo della CTA di lancio.
  final String launchCta;

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
    launchCta: 'Lancia Bar qui 🚀',
  ),
  Activity(
    id: 'bombolone',
    emoji: '🍁',
    label: 'Bombolone',
    background: AppColors.coral,
    foreground: AppColors.nightBlue,
    shadow: AppColors.coralShadow,
    launchCta: 'Lancia Bombolone qui 🚀',
  ),
  Activity(
    id: 'chill',
    emoji: '🛋️',
    label: 'Posto Chill',
    background: AppColors.nightBlue,
    foreground: AppColors.cream,
    shadow: AppColors.nightBlue,
    launchCta: 'Lancia Posto Chill qui 🚀',
  ),
  Activity(
    id: 'mangiare',
    emoji: '🍽️',
    label: 'Mangiare',
    background: AppColors.acidGreen,
    foreground: AppColors.nightBlue,
    shadow: AppColors.acidGreenShadow,
    launchCta: 'Lancia Mangiare qui 🚀',
  ),
  Activity(
    id: 'bho',
    emoji: '🎲',
    label: 'Bho, vediamoci e decidiamo',
    background: AppColors.cream,
    foreground: AppColors.nightBlue,
    shadow: AppColors.nightBlue,
    launchCta: 'Lanciamo e decidiamo lì 🚀',
    dashed: true,
  ),
];

Activity activityById(String id) =>
    activities.firstWhere((a) => a.id == id, orElse: () => activities.last);
