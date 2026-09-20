import 'package:latlong2/latlong.dart';

/// Luogo proposto/selezionato (da preset, ricerca o tap sulla mappa).
class PlaceCandidate {
  /// Nome della posizione dell'utente quando la via non è nota.
  static const userPositionName = 'La tua posizione';

  const PlaceCandidate({
    required this.name,
    required this.lat,
    required this.lng,
    this.address,
    this.externalSource,
    this.externalId,
    this.timesUsed = 0,
    this.score = 0,
    this.lastUsedAt,
    this.isUserPosition = false,
    this.accuracyMeters,
  });

  /// La posizione dell'utente scelta come luogo: [name] è la via (se nota) e
  /// [accuracyMeters] la precisione del GPS (per l'alone sulla mappa).
  factory PlaceCandidate.userPosition({
    required LatLng point,
    String? street,
    double? accuracyMeters,
  }) => PlaceCandidate(
    name: street ?? userPositionName,
    lat: point.latitude,
    lng: point.longitude,
    isUserPosition: true,
    accuracyMeters: accuracyMeters,
  );

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
        score: double.tryParse('${row['score'] ?? ''}') ?? 0,
        lastUsedAt: DateTime.tryParse('${row['last_used_at'] ?? ''}'),
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

  /// Punteggio di popolarità del server (piani lanciati + 0,5 × adesioni).
  final double score;

  /// Ultimo piano lanciato qui per questa attività (solo preset).
  final DateTime? lastUsedAt;

  /// Vero se è la posizione dell'utente (puntino blu), non un locale.
  final bool isUserPosition;

  /// Precisione della posizione, in metri (solo per [isUserPosition]).
  final double? accuracyMeters;

  LatLng get point => LatLng(lat, lng);

  /// Via della posizione dell'utente (es. "Via Roma 12"), se nota.
  String? get street =>
      isUserPosition && name != userPositionName ? name : null;

  @override
  bool operator ==(Object other) =>
      other is PlaceCandidate &&
      other.lat == lat &&
      other.lng == lng &&
      other.name == name &&
      other.externalId == externalId &&
      other.isUserPosition == isUserPosition;

  @override
  int get hashCode => Object.hash(name, lat, lng, externalId, isUserPosition);
}
