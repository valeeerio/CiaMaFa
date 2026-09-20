import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../core/constants.dart';
import 'map_style.dart';

/// Tile della mappa: CARTO Voyager nello stile dell'app (chiaro/scuro come il
/// telefono), OpenStreetMap se manca la chiave.
class MapTiles extends StatelessWidget {
  const MapTiles({super.key});

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
    return carto
        ? ColorFiltered(colorFilter: style.filter, child: tiles)
        : tiles;
  }
}
