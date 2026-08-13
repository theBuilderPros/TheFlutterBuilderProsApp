import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:the_builder_studio/app/features/wallet/model/customer_wallet_access.dart';

class CustomerAccessImportService {
  Future<CustomerWalletAccess?> pickAndImportZip() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: const ['zip'],
      withData: true,
    );

    final file = result?.files.single;
    final bytes = file?.bytes;
    if (file == null || bytes == null) {
      return null;
    }

    return importZipBytes(bytes);
  }

  CustomerWalletAccess importZipBytes(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    for (final file in archive.files) {
      if (!file.isFile || !file.name.toLowerCase().endsWith('.txt')) {
        continue;
      }

      final text = utf8.decode(file.content as List<int>);
      return _parseAccessText(text);
    }

    throw const CustomerAccessImportFailure(
      'The selected ZIP does not contain a customer access text file.',
    );
  }

  CustomerWalletAccess _parseAccessText(String text) {
    final fields = <String, String>{};
    for (final line in const LineSplitter().convert(text)) {
      final separatorIndex = line.indexOf(':');
      if (separatorIndex <= 0) {
        continue;
      }

      final key = line.substring(0, separatorIndex).trim().toLowerCase();
      final value = line.substring(separatorIndex + 1).trim();
      fields[key] = value;
    }

    final publicKey = fields['public key'] ?? '';
    if (publicKey.isEmpty) {
      throw const CustomerAccessImportFailure(
        'The selected access file does not include a wallet public key.',
      );
    }

    return CustomerWalletAccess(
      customerName: fields['customer name'] ?? '',
      customerId: fields['customer id'] ?? '',
      phone: fields['phone'] ?? '',
      publicKey: publicKey,
      secret: fields['secret'],
      recoveryPhrase: fields['recovery phrase'],
      derivationPath: fields['derivation path'],
      assetCode: fields['asset code'] ?? '',
    );
  }
}

class CustomerAccessImportFailure implements Exception {
  const CustomerAccessImportFailure(this.message);

  final String message;
}
