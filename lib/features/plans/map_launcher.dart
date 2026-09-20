import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Apre un luogo nell'app di mappe del telefono.
abstract interface class MapLauncher {
  Future<bool> open({
    required double lat,
    required double lng,
    required String label,
  });
}

/// Indirizzo web che l'app di mappe del telefono apre da sé: Apple Maps su iOS,
/// Google Maps altrove.
Uri mapsUri({
  required double lat,
  required double lng,
  required String label,
  TargetPlatform? platform,
}) {
  final apple = (platform ?? defaultTargetPlatform) == TargetPlatform.iOS;
  return apple
      ? Uri.https('maps.apple.com', '/', {'ll': '$lat,$lng', 'q': label})
      : Uri.https('www.google.com', '/maps/search/', {
          'api': '1',
          'query': '$lat,$lng',
        });
}

class UrlMapLauncher implements MapLauncher {
  const UrlMapLauncher();

  @override
  Future<bool> open({
    required double lat,
    required double lng,
    required String label,
  }) async {
    try {
      return await launchUrl(
        mapsUri(lat: lat, lng: lng, label: label),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      return false;
    }
  }
}
