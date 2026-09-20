import 'package:ciamafa/features/places/place_candidate.dart';
import 'package:ciamafa/features/places/place_clusters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

PlaceCandidate p(String n, double lat, double lng) =>
    PlaceCandidate(name: n, lat: lat, lng: lng);

/// Proiettore finto: 1° = [pxPerDegree] pixel (lat verso l'alto).
Offset Function(LatLng) proj(double pxPerDegree) =>
    (l) => Offset(l.longitude * pxPerDegree, -l.latitude * pxPerDegree);

List<String> names(PlaceCluster c) => [for (final x in c.places) x.name];

void main() {
  final a = p('A', 41.0000, 16.0000);
  final b = p('B', 41.0001, 16.0001); // vicinissimo ad A
  final far = p('Far', 41.5, 16.5);

  test('no places → no clusters', () {
    expect(clusterPlaces([], proj(1000)), isEmpty);
  });

  test('a single place is a single (not a numbered circle)', () {
    final r = clusterPlaces([a], proj(1000));
    expect(r, hasLength(1));
    expect(r.single.isSingle, isTrue);
  });

  test('close places merge into one cluster; far ones stay apart', () {
    // A e B distano ~0,14 px a 1000 px/°; Far ~700 px.
    final r = clusterPlaces([a, b, far], proj(1000));
    expect(r, hasLength(2));
    expect(names(r[0]), ['A', 'B']);
    expect(r[0].isSingle, isFalse);
    expect(names(r[1]), ['Far']);
    expect(r[1].isSingle, isTrue);
  });

  test('zooming in (more px per degree) splits the cluster', () {
    final wide = clusterPlaces([a, b], proj(1000)); // ~0,14 px → insieme
    expect(wide, hasLength(1));
    final close = clusterPlaces([a, b], proj(500000)); // ~70 px → separati
    expect(close, hasLength(2));
  });

  test('the radius is configurable and inclusive', () {
    // A e un punto a esattamente 40 px.
    final c = p('C', 41.0, 16.0 + 40 / 1000);
    expect(clusterPlaces([a, c], proj(1000)), hasLength(1)); // 40 <= 40
    expect(clusterPlaces([a, c], proj(1000), radiusPx: 39), hasLength(2));
  });

  test('the cluster centre is the mean of its members', () {
    final r = clusterPlaces([a, b], proj(1000)).single;
    expect(r.center.latitude, closeTo(41.00005, 1e-9));
    expect(r.center.longitude, closeTo(16.00005, 1e-9));
  });

  test('the first member is the anchor (no chain drift)', () {
    // A—B a 30 px, B—C a 30 px, ma A—C a 60 px: C non entra nel gruppo di A.
    final pa = p('A', 41, 16);
    final pb = p('B', 41, 16 + 30 / 1000);
    final pc = p('C', 41, 16 + 60 / 1000);
    final r = clusterPlaces([pa, pb, pc], proj(1000));
    expect(r.map(names).toList(), [
      ['A', 'B'],
      ['C'],
    ]);
  });

  test('id is stable and independent of member order', () {
    final r1 = clusterPlaces([a, b], proj(1000)).single;
    final r2 = clusterPlaces([b, a], proj(1000)).single;
    expect(r1.id, r2.id);
    expect(clusterPlaces([a], proj(1000)).single.id, isNot(r1.id));
  });

  test('order of clusters follows the order of the places', () {
    final r = clusterPlaces([far, a, b], proj(1000));
    expect(r.map(names).toList(), [
      ['Far'],
      ['A', 'B'],
    ]);
  });
}
