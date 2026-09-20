import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/motion.dart';
import '../../core/theme.dart';
import '../../shared/press_effects.dart';
import 'activity.dart';

/// Cosa mostra "Piano lanciato!".
class LaunchedInfo {
  const LaunchedInfo({
    required this.activity,
    required this.placeName,
    required this.planId,
  });

  final Activity activity;
  final String placeName;
  final String planId;
}

/// "Piano lanciato!": blu notte, coriandoli, riepilogo e due CTA.
class LaunchedScreen extends StatefulWidget {
  const LaunchedScreen({super.key, required this.info});

  final LaunchedInfo info;

  @override
  State<LaunchedScreen> createState() => _LaunchedScreenState();
}

class _LaunchedScreenState extends State<LaunchedScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _confetti = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Una sola pioggia di coriandoli, e solo con il movimento attivo.
    if (!Motion.reduced(context) &&
        !_confetti.isAnimating &&
        _confetti.value == 0) {
      _confetti.forward();
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  void _seePlan() {
    // Home e lista sotto, così "indietro" dal piano torna alla lista e poi alla Home.
    context.go('/home');
    context.push('/plans');
    context.push('/plans/${widget.info.planId}');
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.info.activity;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.nightBlue,
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _confetti,
                  builder: (context, _) => CustomPaint(
                    key: const ValueKey('confetti'),
                    painter: _ConfettiPainter(_confetti.value),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Column(
                children: [
                  const Spacer(),
                  const Text('🎉', style: TextStyle(fontSize: 72)),
                  const SizedBox(height: 12),
                  Semantics(
                    header: true,
                    child: Text(
                      'Piano lanciato!',
                      textAlign: TextAlign.center,
                      style: text.headlineLarge?.copyWith(
                        color: AppColors.cream,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Il gruppo ha ricevuto una notifica per '
                    '${a.emoji} ${a.label} a ${widget.info.placeName}.',
                    textAlign: TextAlign.center,
                    style: text.bodyLarge?.copyWith(color: AppColors.cream),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Scade stanotte a mezzanotte',
                    textAlign: TextAlign.center,
                    style: text.bodyMedium?.copyWith(
                      color: AppColors.cream.withValues(alpha: 0.7),
                    ),
                  ),
                  const Spacer(),
                  SolidPress(
                    shadowColor: AppColors.acidGreenShadow,
                    radius: 22,
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _seePlan,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.acidGreen,
                          foregroundColor: AppColors.nightBlue,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        child: const Text('Vedi piano'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => context.go('/home'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.cream,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Torna alla home'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pioggia di coriandoli una tantum: pezzi con posizione, velocità e rotazione
/// fissi (seme costante), così è deterministica e senza stato.
class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t);

  final double t;

  static const _colors = [
    AppColors.acidGreen,
    AppColors.orange,
    AppColors.coral,
    AppColors.cream,
  ];
  static final _pieces = () {
    final r = math.Random(7);
    return List.generate(
      48,
      (i) => (
        x: r.nextDouble(),
        delay: r.nextDouble() * 0.35,
        speed: 0.75 + r.nextDouble() * 0.5,
        drift: (r.nextDouble() - 0.5) * 0.12,
        spin: r.nextDouble() * 6,
        size: 6.0 + r.nextDouble() * 6,
        color: _colors[i % _colors.length],
      ),
    );
  }();

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    for (final p in _pieces) {
      final local = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final y = -20 + (size.height + 40) * local * p.speed;
      final x = size.width * (p.x + p.drift * math.sin(local * 9));
      canvas
        ..save()
        ..translate(x, y)
        ..rotate(p.spin * local * 3)
        ..drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.6,
          ),
          Paint()..color = p.color.withValues(alpha: 1 - local * 0.4),
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
