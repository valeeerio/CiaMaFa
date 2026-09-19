import 'dart:convert';

import 'package:ciamafa/features/places/place_search_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_test/flutter_test.dart';

const _sample = {
  'features': [
    {
      'geometry': {
        'coordinates': [16.7264, 41.0389],
      },
      'properties': {
        'osm_type': 'N',
        'osm_id': 123,
        'name': 'Bar Centrale',
        'street': 'Via Roma',
        'housenumber': '12',
        'city': 'Bitetto',
      },
    },
    {
      'geometry': {
        'coordinates': [16.7, 41.0],
      },
      'properties': {
        'osm_type': 'W',
        'osm_id': 9,
        'street': 'Corso Vittorio Emanuele',
      },
    },
    {'geometry': null, 'properties': {}},
  ],
};

void main() {
  test('parseFeatures maps GeoJSON to candidates and skips invalid ones', () {
    final r = PhotonPlaceSearchRepository.parseFeatures(jsonEncode(_sample));

    expect(r, hasLength(2));
    expect(r[0].name, 'Bar Centrale');
    expect(r[0].address, 'Via Roma 12, Bitetto');
    expect((r[0].lat, r[0].lng), (41.0389, 16.7264));
    expect((r[0].externalSource, r[0].externalId), ('osm', 'node/123'));
    expect(r[1].name, 'Corso Vittorio Emanuele');
    expect(r[1].externalId, 'way/9');
  });

  test('search sends query, limit and location bias', () async {
    late Uri called;
    final repo = PhotonPlaceSearchRepository(
      MockClient((req) async {
        called = req.url;
        return http.Response(jsonEncode(_sample), 200);
      }),
    );

    final r = await repo.search('bar', near: const LatLng(41.0, 16.7));

    expect(r, hasLength(2));
    expect(called.host, 'photon.komoot.io');
    expect(called.queryParameters, {
      'q': 'bar',
      'limit': '5',
      'lat': '41.0',
      'lon': '16.7',
    });
  });

  test('reverse returns null when nothing is found', () async {
    final repo = PhotonPlaceSearchRepository(
      MockClient((_) async => http.Response(jsonEncode({'features': []}), 200)),
    );
    expect(await repo.reverse(const LatLng(0, 0)), isNull);
  });

  test('non-200 responses throw', () async {
    final repo = PhotonPlaceSearchRepository(
      MockClient((_) async => http.Response('x', 503)),
    );
    expect(repo.search('bar'), throwsA(isA<http.ClientException>()));
  });
}
