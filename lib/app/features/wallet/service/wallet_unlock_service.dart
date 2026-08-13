import 'dart:async';
import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/widgets.dart';
import 'package:the_builder_studio/app/features/wallet/model/encrypted_wallet_secret.dart';

class WalletUnlockService with WidgetsBindingObserver {
  WalletUnlockService();

  static const int kdfIterations = 200000;
  static const Duration inactivityTimeout = Duration(minutes: 15);

  final AesGcm _cipher = AesGcm.with256bits();
  Timer? _lockTimer;
  String? _decryptedSecret;

  bool _isObservingLifecycle = false;

  bool get isUnlocked => _decryptedSecret != null;

  String? get unlockedSecret {
    recordActivity();
    return _decryptedSecret;
  }

  void startLifecycleObserver() {
    if (_isObservingLifecycle) {
      return;
    }
    WidgetsBinding.instance.addObserver(this);
    _isObservingLifecycle = true;
  }

  Future<EncryptedWalletSecret> encryptSecret({
    required String secret,
    required String passcode,
  }) async {
    final salt = SecretKeyData.random(length: 16).bytes;
    final secretKey = await _deriveKey(passcode: passcode, salt: salt);
    final box = await _cipher.encryptString(secret, secretKey: secretKey);

    return EncryptedWalletSecret(
      salt: base64Encode(salt),
      nonce: base64Encode(box.nonce),
      cipherText: base64Encode(box.cipherText),
      mac: base64Encode(box.mac.bytes),
      kdfIterations: kdfIterations,
    );
  }

  Future<void> unlock({
    required EncryptedWalletSecret encryptedSecret,
    required String passcode,
  }) async {
    try {
      final salt = base64Decode(encryptedSecret.salt);
      final secretKey = await _deriveKey(
        passcode: passcode,
        salt: salt,
        iterations: encryptedSecret.kdfIterations,
      );
      final box = SecretBox(
        base64Decode(encryptedSecret.cipherText),
        nonce: base64Decode(encryptedSecret.nonce),
        mac: Mac(base64Decode(encryptedSecret.mac)),
      );
      _decryptedSecret = await _cipher.decryptString(box, secretKey: secretKey);
      recordActivity();
    } catch (_) {
      lock();
      throw const WalletUnlockFailure(
        'Could not unlock wallet. Check your passcode.',
      );
    }
  }

  void recordActivity() {
    if (_decryptedSecret == null) {
      return;
    }
    _lockTimer?.cancel();
    _lockTimer = Timer(inactivityTimeout, lock);
  }

  void lock() {
    _lockTimer?.cancel();
    _lockTimer = null;
    _decryptedSecret = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        lock();
        break;
    }
  }

  Future<SecretKey> _deriveKey({
    required String passcode,
    required List<int> salt,
    int iterations = kdfIterations,
  }) {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: 256,
    );
    return pbkdf2.deriveKeyFromPassword(password: passcode, nonce: salt);
  }
}

class WalletUnlockFailure implements Exception {
  const WalletUnlockFailure(this.message);

  final String message;
}
