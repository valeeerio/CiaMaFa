import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../core/motion.dart';

/// Entrata morbida (dissolvenza + scorrimento + scala), una sola volta, con un
/// ritardo proporzionale a [index] per l'effetto a cascata.
///
/// Con "Riduci movimento" l'elemento compare subito.
class StaggeredEntrance extends StatefulWidget {
  const StaggeredEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.maxIndex = 8,
    this.step = Motion.stagger,
    this.duration = Motion.base,
    this.offset = const Offset(0, -14),
    this.fromScale = 0.6,
  });

  final Widget child;
  final int index;
  final int maxIndex;
  final Duration step;
  final Duration duration;
  final Offset offset;
  final double fromScale;

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  double _delayFraction = 0;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (Motion.reduced(context)) {
      _controller.value = 1;
      return;
    }
    final delay = widget.step * math.min(widget.index, widget.maxIndex);
    final total = delay + widget.duration;
    _controller.duration = total;
    _delayFraction = delay.inMicroseconds / total.inMicroseconds;
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = Interval(
          _delayFraction,
          1,
          curve: Motion.soft,
        ).transform(_controller.value);
        return Opacity(
          opacity: (t * 1.6).clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset.lerp(widget.offset, Offset.zero, t)!,
            child: Transform.scale(
              scale: lerpDouble(widget.fromScale, 1, t)!,
              alignment: Alignment.bottomCenter,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
