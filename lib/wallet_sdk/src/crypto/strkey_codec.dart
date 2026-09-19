import 'dart:typed_data';

final class StrKeyCodec {
  const StrKeyCodec();

  static const int _publicKeyVersion = 6 << 3;
  static const int _secretSeedVersion = 18 << 3;
  static const String _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

  String encodeEd25519PublicKey(List<int> key) =>
      _encode(_publicKeyVersion, key);

  String encodeEd25519SecretSeed(List<int> seed) =>
      _encode(_secretSeedVersion, seed);

  Uint8List decodeEd25519PublicKey(String value) =>
      _decode(value, _publicKeyVersion);

  Uint8List decodeEd25519SecretSeed(String value) =>
      _decode(value, _secretSeedVersion);

  bool isValidEd25519PublicKey(String value) {
    try {
      decodeEd25519PublicKey(value);
      return true;
    } on FormatException {
      return false;
    }
  }

  bool isValidEd25519SecretSeed(String value) {
    try {
      decodeEd25519SecretSeed(value);
      return true;
    } on FormatException {
      return false;
    }
  }

  String _encode(int version, List<int> payload) {
    if (payload.length != 32 ||
        payload.any((int byte) => byte < 0 || byte > 255)) {
      throw ArgumentError.value(payload, 'payload', 'Must contain 32 bytes.');
    }

    final Uint8List versioned = Uint8List(33)
      ..[0] = version
      ..setRange(1, 33, payload);
    final int checksum = _crc16Xmodem(versioned);
    final Uint8List encoded = Uint8List(35)
      ..setRange(0, 33, versioned)
      ..[33] = checksum & 0xff
      ..[34] = (checksum >> 8) & 0xff;
    return _base32Encode(encoded);
  }

  Uint8List _decode(String value, int expectedVersion) {
    if (value.length != 56 || value != value.toUpperCase()) {
      throw const FormatException('Invalid StrKey format.');
    }

    final Uint8List decoded = _base32Decode(value);
    if (decoded.length != 35 || decoded[0] != expectedVersion) {
      throw const FormatException('Invalid StrKey version or length.');
    }

    final int expectedChecksum = decoded[33] | (decoded[34] << 8);
    final int actualChecksum = _crc16Xmodem(decoded.sublist(0, 33));
    if (expectedChecksum != actualChecksum) {
      throw const FormatException('Invalid StrKey checksum.');
    }

    return Uint8List.fromList(decoded.sublist(1, 33));
  }

  String _base32Encode(List<int> bytes) {
    final StringBuffer output = StringBuffer();
    int buffer = 0;
    int bits = 0;
    for (final int byte in bytes) {
      buffer = (buffer << 8) | byte;
      bits += 8;
      while (bits >= 5) {
        bits -= 5;
        output.write(_alphabet[(buffer >> bits) & 31]);
      }
    }
    if (bits > 0) {
      output.write(_alphabet[(buffer << (5 - bits)) & 31]);
    }
    return output.toString();
  }

  Uint8List _base32Decode(String value) {
    final BytesBuilder output = BytesBuilder(copy: false);
    int buffer = 0;
    int bits = 0;
    for (final int codeUnit in value.codeUnits) {
      final int digit = _alphabet.indexOf(String.fromCharCode(codeUnit));
      if (digit < 0) {
        throw const FormatException('Invalid Base32 character.');
      }
      buffer = (buffer << 5) | digit;
      bits += 5;
      if (bits >= 8) {
        bits -= 8;
        output.addByte((buffer >> bits) & 0xff);
      }
    }
    if (bits > 0 && (buffer & ((1 << bits) - 1)) != 0) {
      throw const FormatException('Non-zero Base32 trailing bits.');
    }
    return output.takeBytes();
  }

  int _crc16Xmodem(List<int> bytes) {
    int crc = 0;
    for (final int byte in bytes) {
      crc ^= byte << 8;
      for (int bit = 0; bit < 8; bit++) {
        crc = (crc & 0x8000) != 0 ? (crc << 1) ^ 0x1021 : crc << 1;
        crc &= 0xffff;
      }
    }
    return crc;
  }
}
