import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'place_candidate.dart';

abstract interface class PlaceSearchRepository {
  Future<List<PlaceCandidate>> search(String query, {LatLng? near});

  /// Luogo più vicino al punto, `null` se non c'è nulla.
  Future<PlaceCandidate?> reverse(LatLng point);
}

/// Photon (geocoding OSM, senza chiave). Servizio pubblico a uso equo.
class PhotonPlaceSearchRepository implements PlaceSearchRepository {
  PhotonPlaceSearchRepository(this._client);

  final http.Client _client;

  static const _host = 'photon.komoot.io';
  static const _headers = {
    'User-Agent': 'CiaMaFa/1.0 (com.valeriomortella.ciamafa)',
  };

  @override
  Future<List<PlaceCandidate>> search(String query, {LatLng? near}) async {
    final uri = Uri.https(_host, '/api/', {
      'q': query,
      'limit': '5',
      if (near != null) 'lat': '${near.latitude}',
      if (near != null) 'lon': '${near.longitude}',
    });
    return parseFeatures(await _get(uri));
  }

  @override
  Future<PlaceCandidate?> reverse(LatLng point) async {
    final uri = Uri.https(_host, '/reverse', {
      'lat': '${point.latitude}',
      'lon': '${point.longitude}',
      'limit': '1',
    });
    final results = parseFeatures(await _get(uri));
    return results.isEmpty ? null : results.first;
  }

  Future<String> _get(Uri uri) async {
    final response = await _client.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw http.ClientException('Photon ${response.statusCode}', uri);
    }
    return utf8.decode(response.bodyBytes);
  }

  /// Converte la risposta GeoJSON di Photon in candidati.
  static List<PlaceCandidate> parseFeatures(String body) {
    final features =
        (jsonDecode(body) as Map<String, dynamic>)['features'] as List? ?? [];
    final result = <PlaceCandidate>[];
    for (final f in features) {
      final props = (f['properties'] as Map<String, dynamic>?) ?? {};
      final coords = (f['geometry']?['coordinates'] as List?)?.cast<num>();
      if (coords == null || coords.length < 2) continue;

      final street = props['street'] as String?;
      final house = props['housenumber'] as String?;
      final streetLine = street == null
          ? null
          : (house == null ? street : '$street $house');
      final name =
          (props['name'] as String?) ?? streetLine ?? 'Punto sulla mappa';
      final city =
          (props['city'] ?? props['town'] ?? props['village']) as String?;
      final address = [
        if (streetLine != null && streetLine != name) streetLine,
        if (city != null && city != name) city,
      ].join(', ');

      final osmType = switch (props['osm_type']) {
        'N' => 'node',
        'W' => 'way',
        'R' => 'relation',
        _ => null,
      };
      final osmId = props['osm_id'];
      result.add(
        PlaceCandidate(
          name: name,
          address: address.isEmpty ? null : address,
          lat: coords[1].toDouble(),
          lng: coords[0].toDouble(),
          externalSource: 'osm',
          externalId: osmType != null && osmId != null
              ? '$osmType/$osmId'
              : null,
        ),
      );
    }
    return result;
  }
}
