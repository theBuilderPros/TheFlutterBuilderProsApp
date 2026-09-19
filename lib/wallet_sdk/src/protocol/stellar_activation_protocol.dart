import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:the_builder_pros/wallet_sdk/src/crypto/strkey_codec.dart';
import 'package:the_builder_pros/wallet_sdk/src/protocol/xdr/stellar_xdr_constants.g.dart';
import 'package:the_builder_pros/wallet_sdk/src/protocol/xdr/xdr_codec.dart';

enum StellarActivationOperationType { createAccount, changeTrust, payment }

final class StellarAsset {
  StellarAsset.native() : code = null, issuer = null;

  StellarAsset.credit({required this.code, required this.issuer}) {
    final List<int> bytes = ascii.encode(code!);
    if (bytes.length > 12 ||
        bytes.isEmpty ||
        !RegExp(r'^[A-Za-z0-9]+$').hasMatch(code!)) {
      throw ArgumentError.value(
        code,
        'code',
        'Must be 1-12 ASCII alphanumerics.',
      );
    }
    const StrKeyCodec().decodeEd25519PublicKey(issuer!);
  }

  final String? code;
  final String? issuer;

  bool get isNative => code == null;

  @override
  bool operator ==(Object other) =>
      other is StellarAsset && other.code == code && other.issuer == issuer;

  @override
  int get hashCode => Object.hash(code, issuer);
}

sealed class StellarActivationOperation {
  const StellarActivationOperation({this.sourceAccount});

  final String? sourceAccount;
  StellarActivationOperationType get type;
}

final class StellarCreateAccountOperation extends StellarActivationOperation {
  const StellarCreateAccountOperation({
    required this.destination,
    required this.startingBalance,
    super.sourceAccount,
  });

  final String destination;
  final int startingBalance;
  @override
  StellarActivationOperationType get type =>
      StellarActivationOperationType.createAccount;
}

final class StellarChangeTrustOperation extends StellarActivationOperation {
  const StellarChangeTrustOperation({
    required this.asset,
    required this.limit,
    required super.sourceAccount,
  });

  final StellarAsset asset;
  final int limit;
  @override
  StellarActivationOperationType get type =>
      StellarActivationOperationType.changeTrust;
}

final class StellarPaymentOperation extends StellarActivationOperation {
  const StellarPaymentOperation({
    required this.destination,
    required this.asset,
    required this.amount,
    super.sourceAccount,
  });

  final String destination;
  final StellarAsset asset;
  final int amount;
  @override
  StellarActivationOperationType get type =>
      StellarActivationOperationType.payment;
}

final class StellarDecoratedSignature {
  StellarDecoratedSignature({
    required List<int> hint,
    required List<int> signature,
  }) : hint = Uint8List.fromList(hint),
       signature = Uint8List.fromList(signature) {
    if (this.hint.length != 4) {
      throw ArgumentError.value(hint.length, 'hint.length', 'Must be 4.');
    }
    if (this.signature.length > StellarXdrConstants.maxSignatureBytes) {
      throw ArgumentError.value(signature.length, 'signature.length');
    }
  }

  final Uint8List hint;
  final Uint8List signature;
}

final class StellarActivationEnvelope {
  StellarActivationEnvelope({
    required this.sourceAccount,
    required this.fee,
    required this.sequenceNumber,
    required List<StellarActivationOperation> operations,
    this.minTime,
    this.maxTime,
    List<StellarDecoratedSignature> signatures =
        const <StellarDecoratedSignature>[],
  }) : operations = List.unmodifiable(operations),
       signatures = List.unmodifiable(signatures) {
    const StrKeyCodec().decodeEd25519PublicKey(sourceAccount);
    if (fee < 0 || fee > 0xffffffff) {
      throw RangeError.range(fee, 0, 0xffffffff, 'fee');
    }
    if (operations.isEmpty || operations.length > 3) {
      throw ArgumentError.value(
        operations.length,
        'operations.length',
        'Activation envelopes require 1-3 allowed operations.',
      );
    }
    if ((minTime == null) != (maxTime == null)) {
      throw ArgumentError(
        'minTime and maxTime must both be set or both be null.',
      );
    }
    if ((minTime ?? 0) < 0 || (maxTime ?? 0) < 0) {
      throw ArgumentError('Time bounds cannot be negative.');
    }
    if (signatures.length > StellarXdrConstants.maxSignatures) {
      throw ArgumentError.value(signatures.length, 'signatures.length');
    }
  }

  final String sourceAccount;
  final int fee;
  final int sequenceNumber;
  final int? minTime;
  final int? maxTime;
  final List<StellarActivationOperation> operations;
  final List<StellarDecoratedSignature> signatures;

  StellarActivationEnvelope withSignatures(
    List<StellarDecoratedSignature> newSignatures,
  ) => StellarActivationEnvelope(
    sourceAccount: sourceAccount,
    fee: fee,
    sequenceNumber: sequenceNumber,
    minTime: minTime,
    maxTime: maxTime,
    operations: operations,
    signatures: newSignatures,
  );
}

final class StellarActivationProtocol {
  StellarActivationProtocol({
    StrKeyCodec strKeyCodec = const StrKeyCodec(),
    Ed25519? ed25519,
    Sha256? sha256,
  }) : _strKey = strKeyCodec,
       _ed25519 = ed25519 ?? Ed25519(),
       _sha256 = sha256 ?? Sha256();

  static const String testNetworkPassphrase =
      'Test SDF Network ; September 2015';
  static const String publicNetworkPassphrase =
      'Public Global Stellar Network ; September 2015';

  final StrKeyCodec _strKey;
  final Ed25519 _ed25519;
  final Sha256 _sha256;

  Uint8List encodeEnvelope(StellarActivationEnvelope envelope) {
    final XdrWriter writer = XdrWriter()
      ..writeInt32(StellarXdrConstants.envelopeTypeTransaction);
    _writeTransaction(writer, envelope);
    writer.writeArrayLength(
      envelope.signatures.length,
      StellarXdrConstants.maxSignatures,
    );
    for (final StellarDecoratedSignature signature in envelope.signatures) {
      writer
        ..writeFixedOpaque(signature.hint, 4)
        ..writeVariableOpaque(
          signature.signature,
          StellarXdrConstants.maxSignatureBytes,
        );
    }
    return writer.takeBytes();
  }

  String encodeEnvelopeBase64(StellarActivationEnvelope envelope) =>
      base64Encode(encodeEnvelope(envelope));

  StellarActivationEnvelope decodeEnvelope(List<int> bytes) {
    final XdrReader reader = XdrReader(bytes);
    _expect(
      reader.readInt32(),
      StellarXdrConstants.envelopeTypeTransaction,
      'envelope type',
    );
    final StellarActivationEnvelope unsigned = _readTransaction(reader);
    final int signatureCount = reader.readArrayLength(
      StellarXdrConstants.maxSignatures,
    );
    final List<StellarDecoratedSignature> signatures =
        <StellarDecoratedSignature>[];
    for (int index = 0; index < signatureCount; index++) {
      signatures.add(
        StellarDecoratedSignature(
          hint: reader.readFixedOpaque(4),
          signature: reader.readVariableOpaque(
            StellarXdrConstants.maxSignatureBytes,
          ),
        ),
      );
    }
    reader.ensureFinished();
    return unsigned.withSignatures(signatures);
  }

  StellarActivationEnvelope decodeEnvelopeBase64(String encoded) {
    try {
      return decodeEnvelope(base64Decode(encoded));
    } on FormatException catch (error) {
      throw XdrFormatException('Invalid activation envelope: ${error.message}');
    }
  }

  Future<Uint8List> transactionHash(
    StellarActivationEnvelope envelope,
    String networkPassphrase,
  ) async {
    final Hash networkId = await _sha256.hash(utf8.encode(networkPassphrase));
    final XdrWriter payload = XdrWriter()
      ..writeFixedOpaque(networkId.bytes, 32)
      ..writeInt32(StellarXdrConstants.envelopeTypeTransaction);
    _writeTransaction(payload, envelope);
    final Hash digest = await _sha256.hash(payload.takeBytes());
    return Uint8List.fromList(digest.bytes);
  }

  Future<StellarActivationEnvelope> sign(
    StellarActivationEnvelope envelope, {
    required String secretSeed,
    required String networkPassphrase,
  }) async {
    if (envelope.signatures.length >= StellarXdrConstants.maxSignatures) {
      throw const XdrFormatException('Envelope signature limit reached.');
    }
    final Uint8List seed = _strKey.decodeEd25519SecretSeed(secretSeed);
    final SimpleKeyPair keyPair = await _ed25519.newKeyPairFromSeed(seed);
    final SimplePublicKey publicKey = await keyPair.extractPublicKey();
    final Uint8List hash = await transactionHash(envelope, networkPassphrase);
    final Signature signed = await _ed25519.sign(hash, keyPair: keyPair);
    final Uint8List hint = Uint8List.fromList(publicKey.bytes.sublist(28));
    if (envelope.signatures.any(
      (StellarDecoratedSignature value) => _bytesEqual(value.hint, hint),
    )) {
      throw const XdrFormatException('Signer hint already exists.');
    }
    return envelope.withSignatures(<StellarDecoratedSignature>[
      ...envelope.signatures,
      StellarDecoratedSignature(hint: hint, signature: signed.bytes),
    ]);
  }

  Future<bool> verifySignature(
    StellarActivationEnvelope envelope, {
    required StellarDecoratedSignature signature,
    required String publicAccount,
    required String networkPassphrase,
  }) async {
    final Uint8List publicBytes = _strKey.decodeEd25519PublicKey(publicAccount);
    if (!_bytesEqual(signature.hint, publicBytes.sublist(28))) {
      return false;
    }
    final Uint8List hash = await transactionHash(envelope, networkPassphrase);
    return _ed25519.verify(
      hash,
      signature: Signature(
        signature.signature,
        publicKey: SimplePublicKey(publicBytes, type: KeyPairType.ed25519),
      ),
    );
  }

  void _writeTransaction(XdrWriter writer, StellarActivationEnvelope envelope) {
    _writeMuxedAccount(writer, envelope.sourceAccount);
    writer
      ..writeUint32(envelope.fee)
      ..writeInt64(envelope.sequenceNumber);
    if (envelope.minTime == null) {
      writer.writeInt32(StellarXdrConstants.preconditionNone);
    } else {
      writer
        ..writeInt32(StellarXdrConstants.preconditionTime)
        ..writeUint64(envelope.minTime!)
        ..writeUint64(envelope.maxTime!);
    }
    writer
      ..writeInt32(StellarXdrConstants.memoNone)
      ..writeArrayLength(
        envelope.operations.length,
        StellarXdrConstants.maxOperations,
      );
    for (final StellarActivationOperation operation in envelope.operations) {
      _writeOperation(writer, operation);
    }
    writer.writeInt32(StellarXdrConstants.extensionV0);
  }

  StellarActivationEnvelope _readTransaction(XdrReader reader) {
    final String sourceAccount = _readMuxedAccount(reader);
    final int fee = reader.readUint32();
    final int sequenceNumber = reader.readInt64();
    final int precondition = reader.readInt32();
    int? minTime;
    int? maxTime;
    if (precondition == StellarXdrConstants.preconditionTime) {
      minTime = reader.readUint64();
      maxTime = reader.readUint64();
    } else {
      _expect(
        precondition,
        StellarXdrConstants.preconditionNone,
        'precondition type',
      );
    }
    _expect(reader.readInt32(), StellarXdrConstants.memoNone, 'memo type');
    final int operationCount = reader.readArrayLength(
      StellarXdrConstants.maxOperations,
    );
    if (operationCount == 0 || operationCount > 3) {
      throw const XdrFormatException(
        'Activation envelope operation count is outside the allow-list.',
      );
    }
    final List<StellarActivationOperation> operations =
        <StellarActivationOperation>[];
    for (int index = 0; index < operationCount; index++) {
      operations.add(_readOperation(reader));
    }
    _expect(reader.readInt32(), StellarXdrConstants.extensionV0, 'extension');
    return StellarActivationEnvelope(
      sourceAccount: sourceAccount,
      fee: fee,
      sequenceNumber: sequenceNumber,
      minTime: minTime,
      maxTime: maxTime,
      operations: operations,
    );
  }

  void _writeOperation(XdrWriter writer, StellarActivationOperation operation) {
    writer.writeBool(operation.sourceAccount != null);
    if (operation.sourceAccount != null) {
      _writeMuxedAccount(writer, operation.sourceAccount!);
    }
    switch (operation) {
      case StellarCreateAccountOperation value:
        writer.writeInt32(StellarXdrConstants.operationCreateAccount);
        _writeAccountId(writer, value.destination);
        writer.writeInt64(value.startingBalance);
      case StellarChangeTrustOperation value:
        writer.writeInt32(StellarXdrConstants.operationChangeTrust);
        _writeAsset(writer, value.asset, allowNative: false);
        writer.writeInt64(value.limit);
      case StellarPaymentOperation value:
        writer.writeInt32(StellarXdrConstants.operationPayment);
        _writeMuxedAccount(writer, value.destination);
        _writeAsset(writer, value.asset, allowNative: true);
        writer.writeInt64(value.amount);
    }
  }

  StellarActivationOperation _readOperation(XdrReader reader) {
    final String? sourceAccount = reader.readBool()
        ? _readMuxedAccount(reader)
        : null;
    final int type = reader.readInt32();
    switch (type) {
      case StellarXdrConstants.operationCreateAccount:
        return StellarCreateAccountOperation(
          sourceAccount: sourceAccount,
          destination: _readAccountId(reader),
          startingBalance: reader.readInt64(),
        );
      case StellarXdrConstants.operationChangeTrust:
        if (sourceAccount == null) {
          throw const XdrFormatException(
            'Activation change-trust operation requires its Builder source.',
          );
        }
        return StellarChangeTrustOperation(
          sourceAccount: sourceAccount,
          asset: _readAsset(reader, allowNative: false),
          limit: reader.readInt64(),
        );
      case StellarXdrConstants.operationPayment:
        return StellarPaymentOperation(
          sourceAccount: sourceAccount,
          destination: _readMuxedAccount(reader),
          asset: _readAsset(reader, allowNative: true),
          amount: reader.readInt64(),
        );
      default:
        throw XdrFormatException('Unsupported operation discriminant: $type.');
    }
  }

  void _writeMuxedAccount(XdrWriter writer, String account) {
    writer.writeInt32(StellarXdrConstants.keyTypeEd25519);
    writer.writeFixedOpaque(_strKey.decodeEd25519PublicKey(account), 32);
  }

  String _readMuxedAccount(XdrReader reader) {
    _expect(
      reader.readInt32(),
      StellarXdrConstants.keyTypeEd25519,
      'account key type',
    );
    return _strKey.encodeEd25519PublicKey(reader.readFixedOpaque(32));
  }

  void _writeAccountId(XdrWriter writer, String account) =>
      _writeMuxedAccount(writer, account);

  String _readAccountId(XdrReader reader) => _readMuxedAccount(reader);

  void _writeAsset(
    XdrWriter writer,
    StellarAsset asset, {
    required bool allowNative,
  }) {
    if (asset.isNative) {
      if (!allowNative) {
        throw const XdrFormatException('Native asset is not valid here.');
      }
      writer.writeInt32(StellarXdrConstants.assetNative);
      return;
    }
    final List<int> code = ascii.encode(asset.code!);
    final int width = code.length <= 4 ? 4 : 12;
    writer.writeInt32(
      width == 4
          ? StellarXdrConstants.assetAlphaNum4
          : StellarXdrConstants.assetAlphaNum12,
    );
    writer.writeFixedOpaque(<int>[
      ...code,
      ...List<int>.filled(width - code.length, 0),
    ], width);
    _writeAccountId(writer, asset.issuer!);
  }

  StellarAsset _readAsset(XdrReader reader, {required bool allowNative}) {
    final int type = reader.readInt32();
    if (type == StellarXdrConstants.assetNative) {
      if (!allowNative) {
        throw const XdrFormatException('Native asset is not valid here.');
      }
      return StellarAsset.native();
    }
    final int width;
    if (type == StellarXdrConstants.assetAlphaNum4) {
      width = 4;
    } else if (type == StellarXdrConstants.assetAlphaNum12) {
      width = 12;
    } else {
      throw XdrFormatException('Unsupported asset discriminant: $type.');
    }
    final List<int> padded = reader.readFixedOpaque(width);
    final int zero = padded.indexOf(0);
    final List<int> codeBytes = zero < 0 ? padded : padded.sublist(0, zero);
    if (zero >= 0 && padded.skip(zero).any((int byte) => byte != 0)) {
      throw const XdrFormatException('Invalid asset-code padding.');
    }
    final String code;
    try {
      code = ascii.decode(codeBytes);
    } on FormatException {
      throw const XdrFormatException('Asset code is not ASCII.');
    }
    return StellarAsset.credit(code: code, issuer: _readAccountId(reader));
  }

  void _expect(int actual, int expected, String field) {
    if (actual != expected) {
      throw XdrFormatException('Unsupported $field discriminant: $actual.');
    }
  }

  bool _bytesEqual(List<int> left, List<int> right) {
    if (left.length != right.length) {
      return false;
    }
    int difference = 0;
    for (int index = 0; index < left.length; index++) {
      difference |= left[index] ^ right[index];
    }
    return difference == 0;
  }
}
