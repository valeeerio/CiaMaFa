import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Perché non si è potuta ottenere la posizione.
enum LocationFailureReason {
  /// La posizione è spenta sul telefono.
  serviceDisabled,

  /// Permesso non concesso (si può richiedere di nuovo).
  denied,

  /// Permesso negato in modo definitivo: si può cambiare solo dalle impostazioni.
  deniedForever,

  /// Nessuna posizione entro il tempo massimo (es. simulatore senza posizione).
  timeout,

  /// Errore imprevisto.
  unavailable;

  /// Messaggio per l'utente.
  String get message => switch (this) {
    serviceDisabled =>
      'La posizione è spenta: attivala dalle impostazioni del telefono.',
    denied => 'Serve il permesso di posizione per trovarti.',
    deniedForever =>
      'Il permesso di posizione è negato: abilitalo dalle impostazioni.',
    timeout => 'Non riesco a trovarti in questo momento. Riprova tra poco.',
    unavailable => 'Non riesco a trovarti. Riprova.',
  };

  /// Si risolve solo dalle impostazioni di sistema → tasto "Impostazioni".
  bool get needsSettings => this == serviceDisabled || this == deniedForever;
}

sealed class LocationResult {
  const LocationResult();
}

final class LocationFound extends LocationResult {
  const LocationFound(this.point);

  final LatLng point;
}

final class LocationFailure extends LocationResult {
  const LocationFailure(this.reason);

  final LocationFailureReason reason;
}

abstract interface class LocationService {
  /// Posizione attuale, oppure il motivo per cui non è disponibile.
  Future<LocationResult> locate();

  /// Apre le impostazioni giuste per [reason] (posizione spenta o permesso
  /// negato per sempre).
  Future<void> openSettings(LocationFailureReason reason);
}

/// Il minimo di `Geolocator` che serve: separato per poter testare la logica.
abstract interface class GeolocatorGateway {
  Future<bool> isServiceEnabled();
  Future<LocationPermission> checkPermission();
  Future<LocationPermission> requestPermission();

  /// Lancia [TimeoutException] se non arriva nulla entro [timeLimit].
  Future<LatLng> currentPosition({required Duration timeLimit});
  Future<bool> openAppSettings();
  Future<bool> openLocationSettings();
}

class PlatformGeolocatorGateway implements GeolocatorGateway {
  const PlatformGeolocatorGateway();

  @override
  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  @override
  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();

  @override
  Future<LocationPermission> requestPermission() =>
      Geolocator.requestPermission();

  @override
  Future<LatLng> currentPosition({required Duration timeLimit}) async {
    final p = await Geolocator.getCurrentPosition(
      // Basta ~100 m per scegliere un posto: più veloce dell'alta precisione.
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: timeLimit,
      ),
    );
    return LatLng(p.latitude, p.longitude);
  }

  @override
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}

class GeolocatorLocationService implements LocationService {
  GeolocatorLocationService([GeolocatorGateway? gateway])
    : _gateway = gateway ?? const PlatformGeolocatorGateway();

  final GeolocatorGateway _gateway;

  /// Tempo massimo di attesa per una posizione.
  static const timeLimit = Duration(seconds: 8);

  @override
  Future<LocationResult> locate() async {
    try {
      if (!await _gateway.isServiceEnabled()) {
        return const LocationFailure(LocationFailureReason.serviceDisabled);
      }
      var permission = await _gateway.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await _gateway.requestPermission();
      }
      switch (permission) {
        case LocationPermission.deniedForever:
          return const LocationFailure(LocationFailureReason.deniedForever);
        case LocationPermission.denied:
        case LocationPermission.unableToDetermine:
          return const LocationFailure(LocationFailureReason.denied);
        case LocationPermission.whileInUse:
        case LocationPermission.always:
          break;
      }
      return LocationFound(
        await _gateway.currentPosition(timeLimit: timeLimit),
      );
    } on TimeoutException {
      return const LocationFailure(LocationFailureReason.timeout);
    } on PermissionDeniedException {
      return const LocationFailure(LocationFailureReason.denied);
    } on LocationServiceDisabledException {
      return const LocationFailure(LocationFailureReason.serviceDisabled);
    } catch (_) {
      return const LocationFailure(LocationFailureReason.unavailable);
    }
  }

  @override
  Future<void> openSettings(LocationFailureReason reason) async {
    try {
      if (reason == LocationFailureReason.serviceDisabled) {
        await _gateway.openLocationSettings();
      } else {
        await _gateway.openAppSettings();
      }
    } catch (_) {
      // Se non si aprono le impostazioni non c'è altro da fare.
    }
  }
}
