import 'dart:typed_data';

final class XdrFormatException extends FormatException {
  const XdrFormatException(super.message);
}

final class XdrWriter {
  final BytesBuilder _bytes = BytesBuilder(copy: false);

  void writeInt32(int value) {
    if (value < -0x80000000 || value > 0x7fffffff) {
      throw RangeError.range(value, -0x80000000, 0x7fffffff, 'value');
    }
    final ByteData data = ByteData(4)..setInt32(0, value, Endian.big);
    _bytes.add(data.buffer.asUint8List());
  }

  void writeUint32(int value) {
    if (value < 0 || value > 0xffffffff) {
      throw RangeError.range(value, 0, 0xffffffff, 'value');
    }
    final ByteData data = ByteData(4)..setUint32(0, value, Endian.big);
    _bytes.add(data.buffer.asUint8List());
  }

  void writeInt64(int value) {
    final ByteData data = ByteData(8)..setInt64(0, value, Endian.big);
    _bytes.add(data.buffer.asUint8List());
  }

  void writeUint64(int value) {
    if (value < 0) {
      throw RangeError.value(value, 'value', 'Must be non-negative.');
    }
    final ByteData data = ByteData(8)..setUint64(0, value, Endian.big);
    _bytes.add(data.buffer.asUint8List());
  }

  void writeBool(bool value) => writeInt32(value ? 1 : 0);

  void writeFixedOpaque(List<int> value, int length) {
    if (value.length != length) {
      throw ArgumentError.value(
        value.length,
        'value.length',
        'Expected $length.',
      );
    }
    _validateBytes(value);
    _bytes.add(value);
    _writePadding(length);
  }

  void writeVariableOpaque(List<int> value, int maxLength) {
    if (value.length > maxLength) {
      throw RangeError.range(value.length, 0, maxLength, 'value.length');
    }
    writeUint32(value.length);
    _validateBytes(value);
    _bytes.add(value);
    _writePadding(value.length);
  }

  void writeArrayLength(int length, int maxLength) {
    if (length < 0 || length > maxLength) {
      throw RangeError.range(length, 0, maxLength, 'length');
    }
    writeUint32(length);
  }

  Uint8List takeBytes() => _bytes.takeBytes();

  void _writePadding(int length) {
    final int padding = (4 - (length % 4)) % 4;
    if (padding != 0) {
      _bytes.add(Uint8List(padding));
    }
  }

  void _validateBytes(List<int> value) {
    if (value.any((int byte) => byte < 0 || byte > 255)) {
      throw ArgumentError.value(value, 'value', 'Contains a non-byte value.');
    }
  }
}

final class XdrReader {
  XdrReader(List<int> bytes) : _bytes = Uint8List.fromList(bytes);

  final Uint8List _bytes;
  int _offset = 0;

  int get remaining => _bytes.length - _offset;

  int readInt32() {
    _require(4);
    final int value = ByteData.sublistView(
      _bytes,
      _offset,
      _offset + 4,
    ).getInt32(0, Endian.big);
    _offset += 4;
    return value;
  }

  int readUint32() {
    _require(4);
    final int value = ByteData.sublistView(
      _bytes,
      _offset,
      _offset + 4,
    ).getUint32(0, Endian.big);
    _offset += 4;
    return value;
  }

  int readInt64() {
    _require(8);
    final int value = ByteData.sublistView(
      _bytes,
      _offset,
      _offset + 8,
    ).getInt64(0, Endian.big);
    _offset += 8;
    return value;
  }

  int readUint64() {
    _require(8);
    final int value = ByteData.sublistView(
      _bytes,
      _offset,
      _offset + 8,
    ).getUint64(0, Endian.big);
    _offset += 8;
    if (value < 0) {
      throw const XdrFormatException(
        'Unsigned 64-bit value exceeds Dart range.',
      );
    }
    return value;
  }

  bool readBool() {
    final int value = readInt32();
    if (value != 0 && value != 1) {
      throw const XdrFormatException('Invalid XDR boolean discriminant.');
    }
    return value == 1;
  }

  Uint8List readFixedOpaque(int length) {
    if (length < 0) {
      throw RangeError.value(length, 'length');
    }
    _require(length);
    final Uint8List result = Uint8List.fromList(
      _bytes.sublist(_offset, _offset + length),
    );
    _offset += length;
    _readPadding(length);
    return result;
  }

  Uint8List readVariableOpaque(int maxLength) {
    final int length = readUint32();
    if (length > maxLength) {
      throw XdrFormatException('XDR opaque value exceeds bound $maxLength.');
    }
    return readFixedOpaque(length);
  }

  int readArrayLength(int maxLength) {
    final int length = readUint32();
    if (length > maxLength) {
      throw XdrFormatException('XDR array exceeds bound $maxLength.');
    }
    return length;
  }

  void ensureFinished() {
    if (remaining != 0) {
      throw XdrFormatException('Unexpected trailing XDR bytes: $remaining.');
    }
  }

  void _readPadding(int length) {
    final int padding = (4 - (length % 4)) % 4;
    _require(padding);
    for (int index = 0; index < padding; index++) {
      if (_bytes[_offset + index] != 0) {
        throw const XdrFormatException('Non-zero XDR padding.');
      }
    }
    _offset += padding;
  }

  void _require(int length) {
    if (length < 0 || remaining < length) {
      throw const XdrFormatException('Truncated XDR value.');
    }
  }
}
