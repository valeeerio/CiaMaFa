import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion.dart';
import '../../core/theme.dart';
import '../../shared/press_effects.dart';
import '../plans/activity.dart';
import 'place_candidate.dart';
import 'place_style.dart';

/// Altezza di ogni riga dell'elenco.
const placeRowHeight = 56.0;

/// Spazio lasciato libero sopra il foglio (si vede la testata oscurata).
const placeSheetTopGap = 130.0;

/// Cosa si è scelto nel foglio dei luoghi.
sealed class PlaceListChoice {
  const PlaceListChoice();
}

/// "La tua posizione": va cercata (può richiedere qualche secondo).
final class ChoseMe extends PlaceListChoice {
  const ChoseMe();
}

final class ChosePlace extends PlaceListChoice {
  const ChosePlace(this.place);

  final PlaceCandidate place;
}

/// Apre il foglio dei luoghi (quasi a schermo pieno) e restituisce la scelta,
/// o `null` se lo si chiude senza scegliere.
Future<PlaceListChoice?> showPlaceListSheet(
  BuildContext context, {
  required Activity activity,
  required List<PlaceCandidate> presets,
  PlaceCandidate? selected,
}) {
  return showModalBottomSheet<PlaceListChoice>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x611B2A4A), // blu notte al 38%
    elevation: 0,
    sheetAnimationStyle: AnimationStyle(
      duration: Motion.of(context, Motion.base),
      reverseDuration: Motion.of(context, Motion.fast),
      curve: Motion.soft,
    ),
    builder: (context) => PlaceListSheet(
      activity: activity,
      presets: presets,
      selected: selected,
    ),
  );
}

/// Foglio con l'elenco verticale dei luoghi (stile B): "La tua posizione" in
/// cima e i preset già ordinati (più scelti per primi). Ogni riga: nome, ×N
/// (quante volte è stato scelto) e distanza. Toccare una riga chiude il foglio.
class PlaceListSheet extends StatelessWidget {
  const PlaceListSheet({
    super.key,
    required this.activity,
    required this.presets,
    required this.selected,
  });

  final Activity activity;

  /// Preset già ordinati dal server.
  final List<PlaceCandidate> presets;
  final PlaceCandidate? selected;

  @override
  Widget build(BuildContext context) {
    final height = (MediaQuery.sizeOf(context).height - placeSheetTopGap).clamp(
      placeRowHeight * 4,
      double.infinity,
    );
    final text = Theme.of(context).textTheme;
    final maxScore = presets.fold<double>(0, (m, p) => math.max(m, p.score));
    // Medaglie: i primi tre posti già scelti almeno una volta (ordine server).
    final medals = <int, String>{};
    for (final (i, p) in presets.indexed) {
      if (medals.length == 3) break;
      if (p.timesUsed > 0) medals[i] = const ['🥇', '🥈', '🥉'][medals.length];
    }
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(color: Color(0x261B2A4A), offset: Offset(0, -6)),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Semantics(
                button: true,
                label: 'Chiudi l\'elenco dei luoghi',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).pop(),
                  child: const SizedBox(
                    width: double.infinity,
                    height: 26,
                    child: Center(
                      child: SizedBox(
                        width: 40,
                        height: 4,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color(0x381B2A4A),
                            borderRadius: BorderRadius.all(Radius.circular(2)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: 'Luoghi', style: text.headlineSmall),
                        TextSpan(
                          text: '  ${activity.emoji} ${activity.label}',
                          style: text.bodyMedium?.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                  children: [
                    _MeRow(
                      selected: selected?.isUserPosition == true
                          ? selected
                          : null,
                    ),
                    for (final (i, p) in presets.indexed)
                      _PlaceRow(
                        place: p,
                        selected: p == selected,
                        medal: medals[i],
                        popularity: maxScore > 0 ? p.score / maxScore : 0,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Riga "La tua posizione": tratteggiata, poi puntino blu con la via.
class _MeRow extends StatelessWidget {
  const _MeRow({required this.selected});

  final PlaceCandidate? selected;

  @override
  Widget build(BuildContext context) {
    final me = selected;
    final subtitle = me == null
        ? 'Usa dove sei ora'
        : [
            if (me.street != null) PlaceCandidate.userPositionName,
            if (me.accuracyMeters != null) '±${me.accuracyMeters!.round()} m',
          ].join(' · ');
    return _RowShell(
      rowKey: const ValueKey('row:me'),
      selected: me != null,
      onTap: () => Navigator.of(context).pop(const ChoseMe()),
      leading: _MeIcon(active: me != null),
      title: me?.name ?? PlaceCandidate.userPositionName,
      subtitle: subtitle.isEmpty ? null : subtitle,
    );
  }
}

class _MeIcon extends StatelessWidget {
  const _MeIcon({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    const size = 28.0;
    if (active) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: userPositionBlue,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white, width: 3),
              boxShadow: const [
                BoxShadow(color: Color(0x40000000), offset: Offset(0, 2)),
              ],
            ),
          ),
        ),
      );
    }
    return const SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.fromBorderSide(
            BorderSide(color: AppColors.nightBlue, width: 2),
          ),
        ),
        child: Center(child: Text('📍', style: TextStyle(fontSize: 13))),
      ),
    );
  }
}

class _PlaceRow extends StatelessWidget {
  const _PlaceRow({
    required this.place,
    required this.selected,
    required this.medal,
    required this.popularity,
  });

  final PlaceCandidate place;
  final bool selected;
  final String? medal;

  /// 0–1: punteggio rispetto al più popolare dell'elenco.
  final double popularity;

  @override
  Widget build(BuildContext context) {
    final used = place.timesUsed > 0;
    final last = place.lastUsedAt;
    return _RowShell(
      rowKey: ValueKey('row:${place.name}'),
      selected: selected,
      onTap: () => Navigator.of(context).pop(ChosePlace(place)),
      leading: SizedBox(
        width: 28,
        child: medal == null
            ? null
            : Center(
                child: Text(
                  medal!,
                  key: ValueKey('medal:${place.name}'),
                  style: const TextStyle(fontSize: 20),
                ),
              ),
      ),
      title: place.name,
      stats: used
          ? _Stats(
              popularity: popularity,
              label: [
                '×${place.timesUsed}',
                if (last != null) formatLastUsed(last),
              ].join(' · '),
            )
          : null,
    );
  }
}

/// Barra di popolarità + "×5 · ieri".
class _Stats extends StatelessWidget {
  const _Stats({required this.popularity, required this.label});

  final double popularity;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 84,
          height: 6,
          child: Stack(
            children: [
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0x1F1B2A4A),
                    borderRadius: BorderRadius.all(Radius.circular(3)),
                  ),
                ),
              ),
              FractionallySizedBox(
                key: const ValueKey('popularity-bar'),
                widthFactor: popularity.clamp(0.08, 1.0),
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.acidGreenShadow,
                    borderRadius: BorderRadius.all(Radius.circular(3)),
                  ),
                  child: SizedBox.expand(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
        ),
      ],
    );
  }
}

/// Struttura comune delle righe: [leading] nome (+ sotto) ×N distanza.
class _RowShell extends StatelessWidget {
  const _RowShell({
    required this.rowKey,
    required this.selected,
    required this.onTap,
    required this.title,
    this.subtitle,
    this.leading,
    this.stats,
  });

  final Key rowKey;
  final bool selected;
  final VoidCallback onTap;
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? stats;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: placeRowHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Semantics(
          button: true,
          selected: selected,
          child: PressScale(
            scale: 0.98,
            child: GestureDetector(
              key: rowKey,
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.acidGreen.withValues(alpha: 0.32)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      if (leading != null) ...[
                        leading!,
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.nightBlue,
                              ),
                            ),
                            if (stats != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: stats!,
                              ),
                            if (subtitle != null)
                              Text(
                                subtitle!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.muted,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
