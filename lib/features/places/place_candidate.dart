import 'package:latlong2/latlong.dart';

/// Luogo proposto/selezionato (da preset, ricerca o tap sulla mappa).
class PlaceCandidate {
  const PlaceCandidate({
    required this.name,
    required this.lat,
    required this.lng,
    this.address,
    this.externalSource,
    this.externalId,
  });

  final String name;
  final String? address;
  final double lat;
  final double lng;

  /// Es. `osm` + `node/123`: chiave di `places (external_source, external_id)`.
  final String? externalSource;
  final String? externalId;

  LatLng get point => LatLng(lat, lng);

  @override
  bool operator ==(Object other) =>
      other is PlaceCandidate &&
      other.lat == lat &&
      other.lng == lng &&
      other.name == name &&
      other.externalId == externalId;

  @override
  int get hashCode => Object.hash(name, lat, lng, externalId);
}
