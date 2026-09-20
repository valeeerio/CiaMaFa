import 'package:ciamafa/features/places/place_candidate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('PlaceCandidate.fromPresetRow', () {
    test('reads a full row from activity_presets', () {
      final p = PlaceCandidate.fromPresetRow({
        'name': 'Arco del Tempo',
        'address': 'Via Saverio Burdi, Bitetto',
        'lat': 41.03954,
        'lng': 16.74883,
        'external_source': 'osm',
        'external_id': 'node/6056142322',
        'times_used': 4,
        'yes_votes': 3,
        'score': '5.5',
        'curated': true,
        'last_used_at': '2026-09-19T10:00:00+00:00',
      });
      expect(p.name, 'Arco del Tempo');
      expect(p.address, 'Via Saverio Burdi, Bitetto');
      expect((p.lat, p.lng), (41.03954, 16.74883));
      expect((p.externalSource, p.externalId), ('osm', 'node/6056142322'));
      expect(p.timesUsed, 4);
      expect(p.score, 5.5); // numeric può arrivare come stringa
      expect(p.lastUsedAt, DateTime.utc(2026, 9, 19, 10));
    });

    test('accepts integers as coordinates and missing optional fields', () {
      final p = PlaceCandidate.fromPresetRow({
        'name': 'X',
        'lat': 41,
        'lng': 16,
      });
      expect((p.lat, p.lng), (41.0, 16.0));
      expect(p.address, isNull);
      expect(p.externalId, isNull);
      expect(p.timesUsed, 0); // mai scelto
    });

    test('a null times_used counts as zero', () {
      final p = PlaceCandidate.fromPresetRow({
        'name': 'X',
        'lat': 1.0,
        'lng': 2.0,
        'times_used': null,
      });
      expect(p.timesUsed, 0);
    });

    test('equality ignores the counter (same place, different usage)', () {
      const a = PlaceCandidate(name: 'A', lat: 1, lng: 2, timesUsed: 1);
      const b = PlaceCandidate(name: 'A', lat: 1, lng: 2, timesUsed: 9);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('PlaceCandidate.userPosition', () {
    const here = LatLng(41.0414, 16.7487);

    test('is named "La tua posizione" and has no street', () {
      final p = PlaceCandidate.userPosition(point: here, accuracyMeters: 30);
      expect(p.name, PlaceCandidate.userPositionName);
      expect(p.isUserPosition, isTrue);
      expect(p.street, isNull);
      expect(p.accuracyMeters, 30);
      expect(p.point, here);
    });

    test('with the street, the street is the name', () {
      final p = PlaceCandidate.userPosition(point: here, street: 'Via Roma 12');
      expect(p.name, 'Via Roma 12');
      expect(p.street, 'Via Roma 12');
    });

    test('is not equal to a plain place at the same point', () {
      const plain = PlaceCandidate(
        name: 'La tua posizione',
        lat: 41.0414,
        lng: 16.7487,
      );
      expect(PlaceCandidate.userPosition(point: here), isNot(plain));
    });

    test('a normal place never has a street', () {
      expect(
        const PlaceCandidate(name: 'Via Roma 12', lat: 1, lng: 1).street,
        isNull,
      );
    });
  });

  test('fromPresetRow reads score and last_used_at (null when never used)', () {
    final used = PlaceCandidate.fromPresetRow({
      'name': 'X',
      'lat': 41.0,
      'lng': 16.0,
      'score': 2.5,
      'last_used_at': '2026-09-19T10:00:00+00:00',
    });
    expect(used.score, 2.5);
    expect(used.lastUsedAt, DateTime.utc(2026, 9, 19, 10));
    final fresh = PlaceCandidate.fromPresetRow({
      'name': 'Y',
      'lat': 41.0,
      'lng': 16.0,
      'score': null,
      'last_used_at': null,
    });
    expect(fresh.score, 0);
    expect(fresh.lastUsedAt, isNull);
  });
}
