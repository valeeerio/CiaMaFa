import 'package:ciamafa/features/places/place_style.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatLastUsed', () {
    final now = DateTime(2026, 9, 20, 15);
    String f(DateTime d) => formatLastUsed(d, now: now);

    test('today, yesterday, days', () {
      expect(f(DateTime(2026, 9, 20, 1)), 'oggi');
      expect(f(DateTime(2026, 9, 19, 23)), 'ieri');
      expect(f(DateTime(2026, 9, 17)), '3 giorni fa');
    });

    test('weeks and months', () {
      expect(f(DateTime(2026, 9, 6)), '2 sett. fa');
      expect(f(DateTime(2026, 8, 15)), '1 mese fa');
      expect(f(DateTime(2026, 5, 1)), '4 mesi fa');
    });
  });

  group('userHaloSize', () {
    double halo(double? acc, double zoom) =>
        userHaloSize(accuracyMeters: acc, latitude: 41.04, zoom: zoom);

    test('never smaller than 56 px, even zoomed out', () {
      expect(halo(10, 8), 56);
    });

    test('never bigger than 220 px, even with a poor fix zoomed in', () {
      expect(halo(5000, 18), 220);
    });

    test('grows with zoom and accuracy in between', () {
      expect(halo(80, 17), greaterThan(halo(80, 16)));
      expect(halo(200, 16), greaterThanOrEqualTo(halo(50, 16)));
    });

    test('unknown accuracy behaves like a sensible default', () {
      expect(halo(null, 16), inInclusiveRange(56, 220));
    });
  });
}
