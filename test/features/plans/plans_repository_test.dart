import 'package:ciamafa/features/places/place_candidate.dart';
import 'package:ciamafa/features/plans/plans_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('parseLaunchResult', () {
    LaunchResult parse(Map<String, dynamic> j) =>
        SupabasePlansRepository.parseLaunchResult(j);

    test('launched', () {
      final r = parse({
        'status': 'launched',
        'plan_id': 'p1',
        'place_id': 'x',
        'place_name': 'Pineta',
        'expires_at': '2026-09-20T22:00:00+00:00',
      });
      expect(r, isA<Launched>());
      expect((r as Launched).planId, 'p1');
      expect(r.placeName, 'Pineta');
    });

    test('duplicate carries the existing plan', () {
      final r = parse({'status': 'duplicate', 'plan_id': 'p9'});
      expect((r as DuplicatePlan).planId, 'p9');
    });

    test('needs_confirmation carries the active count', () {
      final r = parse({'status': 'needs_confirmation', 'active_count': 2});
      expect((r as NeedsConfirmation).activeCount, 2);
    });

    test('unknown status is an error, never a silent success', () {
      expect(() => parse({'status': 'boh'}), throwsFormatException);
    });
  });

  group('placeNameForPlan', () {
    test('a normal place keeps its name', () {
      expect(
        placeNameForPlan(const PlaceCandidate(name: 'Pineta', lat: 1, lng: 1)),
        'Pineta',
      );
    });

    test('your position without a street is "Punto sulla mappa"', () {
      expect(
        placeNameForPlan(
          PlaceCandidate.userPosition(point: const LatLng(41, 16)),
        ),
        unnamedPlaceName,
      );
    });

    test('your position with a street uses the street', () {
      expect(
        placeNameForPlan(
          PlaceCandidate.userPosition(
            point: const LatLng(41, 16),
            street: 'Via Roma 12',
          ),
        ),
        'Via Roma 12',
      );
    });
  });

  group('parseAnnouncement', () {
    test('reads nickname, activity and place from the joined row', () {
      final a = SupabasePlansRepository.parseAnnouncement({
        'id': 'p1',
        'emoji': '🍻',
        'label': 'Bar',
        'profiles': {'nickname': 'Marco'},
        'places': {'name': 'Pineta'},
      });
      expect(
        (a.planId, a.nickname, a.emoji, a.label, a.placeName),
        ('p1', 'Marco', '🍻', 'Bar', 'Pineta'),
      );
    });

    test('a plan without place still announces', () {
      final a = SupabasePlansRepository.parseAnnouncement({
        'id': 'p1',
        'emoji': '🍻',
        'label': 'Bar',
        'profiles': {'nickname': 'Marco'},
        'places': null,
      });
      expect(a.placeName, unnamedPlaceName);
    });
  });
}
