import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../shared/map_pin.dart';
import 'map_style.dart';
import 'place_candidate.dart';

/// Mappa con i pin dei preset e del luogo selezionato (con etichetta).
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
    required this.onTapPoint,
    required this.onTapPlace,
    required this.onCenterChanged,
  });

  final MapController controller;
  final LatLng initialCenter;
  final List<PlaceCandidate> presets;
  final PlaceCandidate? selected;
  final ValueChanged<LatLng> onTapPoint;
  final ValueChanged<PlaceCandidate> onTapPlace;
  final ValueChanged<LatLng> onCenterChanged;

  Marker _preset(PlaceCandidate p) => Marker(
    point: p.point,
    width: 40,
    height: 40,
    alignment: Alignment.topCenter,
    child: GestureDetector(
      onTap: () => onTapPlace(p),
      child: const MapPin(selected: false),
    ),
  );

  Marker _selected(PlaceCandidate p) => Marker(
    point: p.point,
    width: 200,
    height: 84,
    alignment: Alignment.topCenter,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(color: Color(0x33000000), blurRadius: 6),
            ],
          ),
          child: Text(
            p.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.nightBlue,
            ),
          ),
        ),
        const MapPin(selected: true),
      ],
    ),
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
        onTap: (_, point) => onTapPoint(point),
        onPositionChanged: (camera, _) => onCenterChanged(camera.center),
      ),
      children: [
        carto ? ColorFiltered(colorFilter: style.filter, child: tiles) : tiles,
        MarkerLayer(
          markers: [
            for (final p in presets)
              if (p != selected) _preset(p),
            if (selected != null) _selected(selected!),
          ],
        ),
        RichAttributionWidget(
          alignment: AttributionAlignment.bottomLeft,
          attributions: [
            TextSourceAttribution(
              carto
                  ? '© OpenStreetMap contributors, © CARTO'
                  : '© OpenStreetMap contributors',
            ),
          ],
        ),
      ],
    );
  }
}
