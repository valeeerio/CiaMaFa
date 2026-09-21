import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

enum PickSource { camera, gallery }

/// Sceglie una foto e la comprime: max 1600 px sul lato lungo, JPEG qualità 80.
abstract interface class ImagePickerService {
  /// I bytes JPEG, o `null` se l'utente annulla (o nega il permesso).
  Future<Uint8List?> pick(PickSource source);
}

class DeviceImagePicker implements ImagePickerService {
  DeviceImagePicker([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  static const maxSide = 1600.0;
  static const quality = 80;

  @override
  Future<Uint8List?> pick(PickSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source == PickSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: maxSide,
        maxHeight: maxSide,
        imageQuality: quality,
      );
      return await file?.readAsBytes();
    } catch (_) {
      // Permesso negato o fotocamera assente: come annullare.
      return null;
    }
  }
}
