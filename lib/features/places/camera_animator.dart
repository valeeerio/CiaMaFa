import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/motion.dart';

class CameraFrame {
  const CameraFrame(this.center, this.zoom);

  final LatLng center;
  final double zoom;
}

/// Punto della traiettoria al tempo [t] (0..1). Con [dip] > 0 lo zoom si
/// allontana a metà volo e poi torna (effetto "arco").
CameraFrame cameraFrame({
  required LatLng from,
  required LatLng to,
  required double fromZoom,
  required double toZoom,
  required double dip,
  required double t,
}) {
  return CameraFrame(
    LatLng(
      lerpDouble(from.latitude, to.latitude, t)!,
      lerpDouble(from.longitude, to.longitude, t)!,
    ),
    lerpDouble(fromZoom, toZoom, t)! - dip * math.sin(math.pi * t),
  );
}

/// Quanto allontanare lo zoom a metà volo: nulla per spostamenti brevi.
double cameraDip(LatLng from, LatLng to) {
  final meters = const Distance().as(LengthUnit.Meter, from, to);
  return meters < 800 ? 0 : math.min(1.5, 0.5 + meters / 4000);
}

/// Sposta la camera della mappa con un volo animato (la `move` di flutter_map
/// è istantanea).
class CameraAnimator {
  CameraAnimator({required TickerProvider vsync, required this.controller})
    : _c = AnimationController(vsync: vsync, duration: Motion.camera) {
    _c.addListener(_tick);
  }

  final MapController controller;
  final AnimationController _c;

  LatLng _from = const LatLng(0, 0);
  LatLng _to = const LatLng(0, 0);
  double _fromZoom = 0;
  double _toZoom = 0;
  double _dip = 0;

  /// Vola verso [target]: con [zoom] esatto, altrimenti con zoom almeno
  /// [minZoom]. Con [reduced] salta subito.
  void flyTo(
    LatLng target, {
    double? zoom,
    double minZoom = 0,
    Duration? duration,
    required bool reduced,
  }) {
    final camera = controller.camera;
    _from = camera.center;
    _fromZoom = camera.zoom;
    _to = target;
    _toZoom = zoom ?? math.max(camera.zoom, minZoom);
    if (reduced) {
      _c.stop();
      controller.move(_to, _toZoom);
      return;
    }
    _dip = cameraDip(_from, _to);
    _c.duration = duration ?? Motion.camera;
    _c.forward(from: 0);
  }

  /// Ingrandisce (+) o riduce (−) di [delta] livelli restando sullo stesso centro.
  void zoomBy(double delta, {required bool reduced}) {
    final camera = controller.camera;
    final z = (camera.zoom + delta).clamp(
      camera.minZoom ?? 3.0,
      camera.maxZoom ?? 19.0,
    );
    flyTo(camera.center, zoom: z, duration: Motion.base, reduced: reduced);
  }

  void _tick() {
    final f = cameraFrame(
      from: _from,
      to: _to,
      fromZoom: _fromZoom,
      toZoom: _toZoom,
      dip: _dip,
      t: Motion.emphasized.transform(_c.value),
    );
    controller.move(f.center, f.zoom);
  }

  void dispose() => _c.dispose();
}
