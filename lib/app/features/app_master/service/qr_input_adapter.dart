import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

enum QrInputFailure { cancelled, permissionDenied, unreadable, multipleCodes }

final class QrInputResult {
  const QrInputResult.value(this.value) : failure = null;

  const QrInputResult.failure(this.failure) : value = null;

  final String? value;
  final QrInputFailure? failure;

  bool get isSuccess => value != null;
}

abstract interface class QrImagePicker {
  Future<String?> pickImagePath();
}

final class GalleryQrImagePicker implements QrImagePicker {
  GalleryQrImagePicker({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<String?> pickImagePath() async =>
      (await _picker.pickImage(source: ImageSource.gallery))?.path;
}

abstract interface class QrImageDecoder {
  Future<BarcodeCapture?> decode(String path);
}

final class MobileScannerImageDecoder implements QrImageDecoder {
  @override
  Future<BarcodeCapture?> decode(String path) async {
    final MobileScannerController controller = MobileScannerController(
      formats: const <BarcodeFormat>[BarcodeFormat.qrCode],
      autoStart: false,
    );
    try {
      return await controller.analyzeImage(path);
    } finally {
      await controller.dispose();
    }
  }
}

final class QrInputAdapter {
  QrInputAdapter({QrImagePicker? imagePicker, QrImageDecoder? imageDecoder})
    : _imagePicker = imagePicker ?? GalleryQrImagePicker(),
      _imageDecoder = imageDecoder ?? MobileScannerImageDecoder();

  final QrImagePicker _imagePicker;
  final QrImageDecoder _imageDecoder;

  Future<QrInputResult> importFromGallery() async {
    final String? path = await _imagePicker.pickImagePath();
    if (path == null) {
      return const QrInputResult.failure(QrInputFailure.cancelled);
    }
    try {
      return fromCapture(await _imageDecoder.decode(path));
    } catch (_) {
      return const QrInputResult.failure(QrInputFailure.unreadable);
    }
  }

  QrInputResult fromCapture(BarcodeCapture? capture) {
    final Set<String> values = <String>{
      for (final Barcode barcode in capture?.barcodes ?? const <Barcode>[])
        if (barcode.rawValue?.isNotEmpty ?? false) barcode.rawValue!,
    };
    if (values.isEmpty) {
      return const QrInputResult.failure(QrInputFailure.unreadable);
    }
    if (values.length != 1) {
      return const QrInputResult.failure(QrInputFailure.multipleCodes);
    }
    return QrInputResult.value(values.single);
  }
}
