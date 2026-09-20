import 'package:ciamafa/features/places/place_candidate.dart';
import 'package:flutter_test/flutter_test.dart';

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
        'distance_km': 0.2,
      });
      expect(p.name, 'Arco del Tempo');
      expect(p.address, 'Via Saverio Burdi, Bitetto');
      expect((p.lat, p.lng), (41.03954, 16.74883));
      expect((p.externalSource, p.externalId), ('osm', 'node/6056142322'));
      expect(p.timesUsed, 4);
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
}
