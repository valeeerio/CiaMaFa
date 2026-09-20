import 'dart:ui';

import 'package:latlong2/latlong.dart';

import 'place_candidate.dart';

/// Gruppo di luoghi che, alla vista attuale, si sovrapporrebbero sulla mappa.
class PlaceCluster {
  const PlaceCluster(this.places, this.center);

  final List<PlaceCandidate> places;

  /// Media delle coordinate dei membri (dove disegnare il cerchio).
  final LatLng center;

  bool get isSingle => places.length == 1;

  /// Chiave stabile: cambia solo se cambia la composizione del gruppo.
  String get id =>
      (places.map((p) => '${p.lat},${p.lng}').toList()..sort()).join('|');
}

/// Raggruppa i luoghi i cui pin distano meno di [radiusPx] pixel a schermo.
///
/// [project] converte le coordinate in pixel per lo zoom attuale (a bassi zoom
/// molti luoghi finiscono nello stesso gruppo, ingrandendo si separano).
/// L'ordine dei gruppi segue quello dei luoghi; il primo membro fa da àncora.
List<PlaceCluster> clusterPlaces(
  List<PlaceCandidate> places,
  Offset Function(LatLng) project, {
  double radiusPx = 40,
}) {
  final anchors = <Offset>[];
  final members = <List<PlaceCandidate>>[];
  for (final p in places) {
    final o = project(p.point);
    var hit = -1;
    for (var i = 0; i < anchors.length; i++) {
      if ((anchors[i] - o).distance <= radiusPx) {
        hit = i;
        break;
      }
    }
    if (hit < 0) {
      anchors.add(o);
      members.add([p]);
    } else {
      members[hit].add(p);
    }
  }
  return [
    for (final m in members)
      PlaceCluster(
        m,
        LatLng(
          m.map((p) => p.lat).reduce((a, b) => a + b) / m.length,
          m.map((p) => p.lng).reduce((a, b) => a + b) / m.length,
        ),
      ),
  ];
}
