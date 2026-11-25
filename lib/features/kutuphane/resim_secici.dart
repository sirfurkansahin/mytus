import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

/// Fotoğraf seçme/çekme soyutlaması.
/// Testlerde sahte görseller sağlamak, uygulamada ise ImagePicker kullanmak için.
abstract class ResimSecici {
  Future<Uint8List?> galeridenSec();
  Future<Uint8List?> kameradanCek();

  static ResimSecici ornek = CihazResimSecici();
}

/// Gerçek cihaz kamerasından veya galerisinden fotoğraf alan servis.
class CihazResimSecici implements ResimSecici {
  final ImagePicker _picker = ImagePicker();

  @override
  Future<Uint8List?> galeridenSec() async {
    try {
      final dosya = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 75,
      );
      if (dosya == null) return null;
      return await dosya.readAsBytes();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Uint8List?> kameradanCek() async {
    try {
      final dosya = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 75,
      );
      if (dosya == null) return null;
      return await dosya.readAsBytes();
    } catch (_) {
      return null;
    }
  }
}

/// Test ortamında kamera veya galeri diyaloglarını taklit eden sahte servis.
class SahteResimSecici implements ResimSecici {
  SahteResimSecici({this.donusBytes});

  Uint8List? donusBytes;

  @override
  Future<Uint8List?> galeridenSec() async => donusBytes;

  @override
  Future<Uint8List?> kameradanCek() async => donusBytes;
}
