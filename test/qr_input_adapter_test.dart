import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:the_builder_pros/app/features/app_master/service/qr_input_adapter.dart';

void main() {
  test('camera capture returns the exact decoded value', () {
    final QrInputResult result = QrInputAdapter().fromCapture(
      const BarcodeCapture(
        barcodes: <Barcode>[Barcode(rawValue: ' exact opaque value ')],
      ),
    );

    expect(result.value, ' exact opaque value ');
  });

  test('image import returns the exact decoded value', () async {
    final QrInputAdapter adapter = QrInputAdapter(
      imagePicker: _Picker('request.png'),
      imageDecoder: _Decoder(
        const BarcodeCapture(
          barcodes: <Barcode>[Barcode(rawValue: '{"opaque":true}')],
        ),
      ),
    );

    final QrInputResult result = await adapter.importFromGallery();

    expect(result.value, '{"opaque":true}');
  });

  test('image cancellation is distinct from unreadable input', () async {
    final QrInputResult cancelled = await QrInputAdapter(
      imagePicker: _Picker(null),
      imageDecoder: _Decoder(null),
    ).importFromGallery();
    final QrInputResult unreadable = await QrInputAdapter(
      imagePicker: _Picker('empty.png'),
      imageDecoder: _Decoder(const BarcodeCapture()),
    ).importFromGallery();

    expect(cancelled.failure, QrInputFailure.cancelled);
    expect(unreadable.failure, QrInputFailure.unreadable);
  });

  test('multiple distinct QR values fail closed', () {
    final QrInputResult result = QrInputAdapter().fromCapture(
      const BarcodeCapture(
        barcodes: <Barcode>[
          Barcode(rawValue: 'first'),
          Barcode(rawValue: 'second'),
        ],
      ),
    );

    expect(result.failure, QrInputFailure.multipleCodes);
  });
}

final class _Picker implements QrImagePicker {
  const _Picker(this.path);

  final String? path;

  @override
  Future<String?> pickImagePath() async => path;
}

final class _Decoder implements QrImageDecoder {
  const _Decoder(this.capture);

  final BarcodeCapture? capture;

  @override
  Future<BarcodeCapture?> decode(String path) async => capture;
}
