import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants.dart';
import '../../core/motion.dart';
import '../../core/theme.dart';
import '../../shared/map_pin.dart';
import '../../shared/staggered_entrance.dart';
import 'map_style.dart';
import 'place_candidate.dart';
import 'place_clusters.dart';
import 'place_style.dart';

/// Mappa con i preset (pin, o cerchi col numero quando si sovrapporrebbero) e il
/// luogo selezionato (atterraggio morbido, onda e etichetta).
///
/// Con `CARTO_API_KEY`: tile CARTO, chiari (crema) o scuri (blu notte) secondo
/// la modalità del dispositivo. Senza chiave: OpenStreetMap standard.
class PlacesMap extends StatelessWidget {
  const PlacesMap({
    super.key,
    required this.controller,
    required this.initialCenter,
    required this.presets,
    required this.selected,
    required this.emoji,
    required this.onTapPoint,
    required this.onTapPlace,
    required this.onTapCluster,
    required this.onCenterChanged,
  });

  final MapController controller;
  final LatLng initialCenter;
  final List<PlaceCandidate> presets;
  final PlaceCandidate? selected;
  final String emoji;
  final ValueChanged<LatLng> onTapPoint;
  final ValueChanged<PlaceCandidate> onTapPlace;
  final ValueChanged<List<PlaceCandidate>> onTapCluster;
  final ValueChanged<LatLng> onCenterChanged;

  static String _id(PlaceCandidate p) => '${p.lat},${p.lng}';

  Marker _ripple(PlaceCandidate p) => Marker(
    key: ValueKey('ripple:${_id(p)}'),
    point: p.point,
    width: 120,
    height: 120,
    child: const IgnorePointer(child: _RippleRing()),
  );

  Marker _selected(PlaceCandidate p) => Marker(
    key: ValueKey('selected:${_id(p)}'),
    point: p.point,
    width: 200,
    height: 96,
    alignment: Alignment.topCenter,
    child: _SelectedPin(place: p, emoji: emoji),
  );

  @override
  Widget build(BuildContext context) {
    final carto = Env.cartoApiKey.isNotEmpty;
    final style = mapStyleFor(MediaQuery.platformBrightnessOf(context));
    final tiles = TileLayer(
      urlTemplate: carto
          ? 'https://{s}.basemaps.cartocdn.com/rastertiles/${style.cartoStyle}/{z}/{x}/{y}{r}.png?key=${Env.cartoApiKey}'
          : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      subdomains: carto ? const ['a', 'b', 'c', 'd'] : const ['a', 'b', 'c'],
      retinaMode: carto && RetinaMode.isHighDensity(context),
      maxNativeZoom: carto ? 20 : 19,
      userAgentPackageName: 'com.valeriomortella.ciamafa',
    );
    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: 15,
        minZoom: 3,
        maxZoom: 19,
        onTap: (_, point) => onTapPoint(point),
        onPositionChanged: (camera, _) => onCenterChanged(camera.center),
      ),
      children: [
        carto ? ColorFiltered(colorFilter: style.filter, child: tiles) : tiles,
        _PresetLayer(
          presets: [
            for (final p in presets)
              if (p != selected) p,
          ],
          emoji: emoji,
          onTapPlace: onTapPlace,
          onTapCluster: onTapCluster,
        ),
        if (selected != null && selected!.isUserPosition)
          _UserPositionLayer(place: selected!)
        else if (selected != null)
          MarkerLayer(markers: [_ripple(selected!), _selected(selected!)]),
      ],
    );
  }
}

/// Preset: un pin per luogo; quelli che a questo zoom si sovrapporrebbero
/// diventano un cerchio col numero (si ricalcola a ogni movimento di camera).
class _PresetLayer extends StatelessWidget {
  const _PresetLayer({
    required this.presets,
    required this.emoji,
    required this.onTapPlace,
    required this.onTapCluster,
  });

  final List<PlaceCandidate> presets;
  final String emoji;
  final ValueChanged<PlaceCandidate> onTapPlace;
  final ValueChanged<List<PlaceCandidate>> onTapCluster;

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    final clusters = clusterPlaces(presets, camera.latLngToScreenOffset);
    return MarkerLayer(
      markers: [
        for (final (i, c) in clusters.indexed)
          if (c.isSingle)
            Marker(
              key: ValueKey('preset:${c.id}'),
              point: c.center,
              width: MapPin.presetSize.width,
              height: MapPin.presetSize.height,
              alignment: Alignment.topCenter,
              child: StaggeredEntrance(
                index: i,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTapPlace(c.places.first),
                  child: MapPin(selected: false, emoji: emoji),
                ),
              ),
            )
          else
            Marker(
              key: ValueKey('cluster:${c.id}'),
              point: c.center,
              width: _ClusterBubble.size,
              height: _ClusterBubble.size,
              child: StaggeredEntrance(
                index: i,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTapCluster(c.places),
                  child: _ClusterBubble(count: c.places.length),
                ),
              ),
            ),
      ],
    );
  }
}

/// Cerchio col numero di luoghi raggruppati (stesso stile dei pin: verde acido,
/// bordo bianco, ombra piena scura).
class _ClusterBubble extends StatelessWidget {
  const _ClusterBubble({required this.count});

  final int count;

  static const size = 46.0;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.acidGreen,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white, width: 4),
        boxShadow: const [
          BoxShadow(color: AppColors.acidGreenShadow, offset: Offset(0, 3)),
        ],
      ),
      child: Center(
        child: Text(
          '$count',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontSize: 18, color: AppColors.nightBlue),
        ),
      ),
    );
  }
}

/// Pin selezionato: "atterra" con scala e discesa morbide, poi compare l'etichetta.
class _SelectedPin extends StatefulWidget {
  const _SelectedPin({required this.place, required this.emoji});

  final PlaceCandidate place;
  final String emoji;

  @override
  State<_SelectedPin> createState() => _SelectedPinState();
}

class _SelectedPinState extends State<_SelectedPin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (Motion.reduced(context)) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final land = Motion.soft.transform(_c.value);
        final label = const Interval(
          0.35,
          1,
          curve: Curves.easeOut,
        ).transform(_c.value);
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Opacity(
              opacity: label,
              child: Transform.translate(
                offset: Offset(0, (1 - label) * 6),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(color: Color(0x331B2A4A), offset: Offset(0, 3)),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    child: Text(
                      widget.place.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.nightBlue,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Transform.translate(
              offset: Offset(0, (1 - land) * -22),
              child: Transform.scale(
                scale: 0.7 + 0.3 * land,
                alignment: Alignment.bottomCenter,
                child: MapPin(selected: true, emoji: widget.emoji),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Onda che si espande una volta sola attorno al pin selezionato.
class _RippleRing extends StatefulWidget {
  const _RippleRing({this.color = AppColors.coral});

  final Color color;

  @override
  State<_RippleRing> createState() => _RippleRingState();
}

class _RippleRingState extends State<_RippleRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!Motion.reduced(context)) _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Motion.reduced(context)) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = Motion.soft.transform(_c.value);
        return CustomPaint(
          painter: _RipplePainter(
            radius: 8 + 50 * t,
            opacity: 0.6 * (1 - t),
            color: widget.color,
          ),
        );
      },
    );
  }
}

class _RipplePainter extends CustomPainter {
  const _RipplePainter({
    required this.radius,
    required this.opacity,
    required this.color,
  });

  final double radius;
  final double opacity;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0.01) return;
    canvas.drawCircle(
      size.center(Offset.zero),
      math.min(radius, size.width / 2),
      Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
  }

  @override
  bool shouldRepaint(_RipplePainter old) =>
      old.radius != radius || old.opacity != opacity || old.color != color;
}

/// La posizione dell'utente: puntino blu con alone (precisione del GPS, in
/// scala con lo zoom), un'onda una tantum e l'etichetta "Sei qui · via".
class _UserPositionLayer extends StatelessWidget {
  const _UserPositionLayer({required this.place});

  final PlaceCandidate place;

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    final halo = userHaloSize(
      accuracyMeters: place.accuracyMeters,
      latitude: place.lat,
      zoom: camera.zoom,
    );
    final id = '${place.lat},${place.lng}';
    final street = place.street;
    return MarkerLayer(
      markers: [
        Marker(
          key: ValueKey('me-halo:$id'),
          point: place.point,
          width: halo,
          height: halo,
          child: IgnorePointer(
            child: Stack(
              alignment: Alignment.center,
              children: [
                const _RippleRing(color: userPositionBlue),
                StaggeredEntrance(
                  fromScale: 0.7,
                  offset: Offset.zero,
                  child: DecoratedBox(
                    key: const ValueKey('me-halo'),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: userPositionBlue.withValues(alpha: 0.18),
                      border: Border.all(
                        color: userPositionBlue.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                    ),
                    child: SizedBox.square(dimension: halo),
                  ),
                ),
              ],
            ),
          ),
        ),
        Marker(
          key: ValueKey('me-dot:$id'),
          point: place.point,
          width: 28,
          height: 28,
          child: IgnorePointer(
            child: StaggeredEntrance(
              fromScale: 0.6,
              offset: Offset.zero,
              child: Container(
                key: const ValueKey('me-dot'),
                decoration: BoxDecoration(
                  color: userPositionBlue,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 3.5),
                  boxShadow: const [
                    BoxShadow(color: Color(0x40000000), offset: Offset(0, 2)),
                  ],
                ),
              ),
            ),
          ),
        ),
        Marker(
          key: ValueKey('me-label:$id'),
          point: place.point,
          width: 240,
          height: 60,
          alignment: Alignment.topCenter,
          child: IgnorePointer(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: StaggeredEntrance(
                  index: 2,
                  fromScale: 0.9,
                  offset: const Offset(0, 6),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x331B2A4A),
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      child: Text(
                        street == null ? 'Sei qui' : 'Sei qui · $street',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.nightBlue,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
