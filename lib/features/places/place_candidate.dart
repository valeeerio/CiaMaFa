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
    this.timesUsed = 0,
  });

  /// Da una riga di `activity_presets` (il server le restituisce già ordinate).
  factory PlaceCandidate.fromPresetRow(Map<String, dynamic> row) =>
      PlaceCandidate(
        name: row['name'] as String,
        address: row['address'] as String?,
        lat: (row['lat'] as num).toDouble(),
        lng: (row['lng'] as num).toDouble(),
        externalSource: row['external_source'] as String?,
        externalId: row['external_id'] as String?,
        timesUsed: (row['times_used'] as num?)?.toInt() ?? 0,
      );

  final String name;
  final String? address;
  final double lat;
  final double lng;

  /// Es. `osm` + `node/123`: chiave di `places (external_source, external_id)`.
  final String? externalSource;
  final String? externalId;

  /// Quante volte il gruppo ha lanciato un piano qui per questa attività
  /// (solo per il contatore sul chip; l'ordine lo decide il server).
  final int timesUsed;

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
