import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

abstract interface class LocationService {
  /// Posizione attuale, `null` se servizio spento, permesso negato o errore.
  Future<LatLng?> currentPosition();
}

class GeolocatorLocationService implements LocationService {
  @override
  Future<LatLng?> currentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          timeLimit: Duration(seconds: 10),
        ),
      );
      return LatLng(p.latitude, p.longitude);
    } catch (_) {
      return null;
    }
  }
}
