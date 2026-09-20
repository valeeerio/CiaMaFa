import 'package:ciamafa/features/plans/map_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iOS opens Apple Maps with the place name', () {
    final u = mapsUri(
      lat: 41.03797,
      lng: 16.73744,
      label: "Frida a'mare",
      platform: TargetPlatform.iOS,
    );
    expect(u.host, 'maps.apple.com');
    expect(u.queryParameters['ll'], '41.03797,16.73744');
    expect(u.queryParameters['q'], "Frida a'mare");
  });

  test('Android opens Google Maps at the coordinates', () {
    final u = mapsUri(
      lat: 41.03797,
      lng: 16.73744,
      label: 'x',
      platform: TargetPlatform.android,
    );
    expect(u.host, 'www.google.com');
    expect(u.queryParameters['query'], '41.03797,16.73744');
  });
}
