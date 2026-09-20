import 'package:flutter/material.dart';

import '../core/motion.dart';

/// Rimpicciolisce leggermente il figlio finché è premuto.
/// Usa un [Listener]: non interferisce con i gesti del figlio.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.scale = 0.95});

  final Widget child;
  final double scale;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _pressed && !Motion.reduced(context) ? widget.scale : 1,
        duration: Motion.of(context, const Duration(milliseconds: 120)),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Ombra piena "a rilievo" (come i pulsanti delle attività): alla pressione il
/// figlio affonda nell'ombra.
class SolidPress extends StatefulWidget {
  const SolidPress({
    super.key,
    required this.child,
    required this.shadowColor,
    this.enabled = true,
    this.radius = 18,
  });

  final Widget child;
  final Color shadowColor;
  final bool enabled;
  final double radius;

  @override
  State<SolidPress> createState() => _SolidPressState();
}

class _SolidPressState extends State<SolidPress> {
  bool _pressed = false;

  void _set(bool v) {
    if (widget.enabled && _pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final down = _pressed && widget.enabled;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedContainer(
        duration: Motion.of(context, const Duration(milliseconds: 110)),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, down ? 3 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          boxShadow: widget.enabled
              ? [
                  BoxShadow(
                    color: widget.shadowColor,
                    offset: Offset(0, down ? 2 : 5),
                  ),
                ]
              : const [],
        ),
        child: widget.child,
      ),
    );
  }
}
