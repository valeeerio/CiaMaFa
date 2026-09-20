import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Pin a goccia con l'emoji dell'attività, come nel prototipo: verde acido =
/// preset, corallo = selezionato. Bordo bianco e ombra piena nella tinta più
/// scura dello stesso colore (come i pulsanti della Home).
class MapPin extends StatelessWidget {
  const MapPin({super.key, required this.selected, this.emoji});

  final bool selected;
  final String? emoji;

  static const presetSize = Size(36, 44);
  static const selectedSize = Size(48, 58);

  Size get size => selected ? selectedSize : presetSize;

  @override
  Widget build(BuildContext context) {
    final s = size;
    return SizedBox.fromSize(
      size: s,
      child: Stack(
        children: [
          CustomPaint(
            size: s,
            painter: _TeardropPainter(
              color: selected ? AppColors.coral : AppColors.acidGreen,
              shadow: selected
                  ? AppColors.coralShadow
                  : AppColors.acidGreenShadow,
            ),
          ),
          if (emoji != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: s.width,
              child: Center(
                child: Text(emoji!, style: TextStyle(fontSize: s.width * 0.4)),
              ),
            ),
        ],
      ),
    );
  }
}

class _TeardropPainter extends CustomPainter {
  const _TeardropPainter({required this.color, required this.shadow});

  final Color color;
  final Color shadow;

  Path _outline(Size s, double r, Offset c) {
    final tip = Offset(s.width / 2, s.height - 4);
    final d = tip.dy - c.dy;
    final a = math.acos(r / d);
    final t1 = c + Offset(r * math.sin(a), r * math.cos(a));
    final t2 = c + Offset(-r * math.sin(a), r * math.cos(a));
    final circle = Path()..addOval(Rect.fromCircle(center: c, radius: r));
    final tri = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(t1.dx, t1.dy)
      ..lineTo(t2.dx, t2.dy)
      ..close();
    return Path.combine(PathOperation.union, circle, tri);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2 - 2;
    final c = Offset(size.width / 2, r + 2);
    final path = _outline(size, r, c);
    canvas.drawPath(
      path.shift(const Offset(0, 3)),
      Paint()..color = AppColors.nightBlue,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawCircle(c, r * 0.68, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_TeardropPainter old) =>
      old.color != color || old.shadow != shadow;
}
