import 'dart:convert';

import 'package:the_builder_studio/app/features/wallet/model/customer_wallet_access.dart';
import 'package:the_builder_studio/app/features/wallet/model/encrypted_wallet_secret.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalletActivationStorageService {
  static const String _walletAccessKey =
      'builder_studio.wallet.persisted_wallet_access';
  static const String _encryptedSecretKey =
      'builder_studio.wallet.encrypted_customer_secret';

  Future<CustomerWalletAccess?> restoreWalletAccess() async {
    final preferences = await SharedPreferences.getInstance();
    final encodedAccess = preferences.getString(_walletAccessKey);
    if (encodedAccess == null || encodedAccess.isEmpty) {
      return null;
    }

    try {
      final decodedAccess = jsonDecode(encodedAccess);
      if (decodedAccess is! Map<String, dynamic>) {
        await clearWalletAccess();
        return null;
      }

      final walletAccess = CustomerWalletAccess.fromPersistedJson(
        decodedAccess,
      );
      if (!walletAccess.hasPublicWallet) {
        await clearWalletAccess();
        return null;
      }

      return walletAccess;
    } catch (_) {
      await clearWalletAccess();
      return null;
    }
  }

  Future<void> saveWalletAccess(CustomerWalletAccess walletAccess) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _walletAccessKey,
      jsonEncode(walletAccess.toPersistedJson()),
    );
  }

  Future<EncryptedWalletSecret?> restoreEncryptedSecret() async {
    final preferences = await SharedPreferences.getInstance();
    final encodedSecret = preferences.getString(_encryptedSecretKey);
    if (encodedSecret == null || encodedSecret.isEmpty) {
      return null;
    }

    try {
      final decodedSecret = jsonDecode(encodedSecret);
      if (decodedSecret is! Map<String, dynamic>) {
        await clearEncryptedSecret();
        return null;
      }
      final secret = EncryptedWalletSecret.fromJson(decodedSecret);
      if (secret.cipherText.isEmpty || secret.salt.isEmpty) {
        await clearEncryptedSecret();
        return null;
      }
      return secret;
    } catch (_) {
      await clearEncryptedSecret();
      return null;
    }
  }

  Future<void> saveEncryptedSecret(EncryptedWalletSecret secret) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _encryptedSecretKey,
      jsonEncode(secret.toJson()),
    );
  }

  Future<void> clearEncryptedSecret() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_encryptedSecretKey);
  }

  Future<void> clearWalletAccess() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_walletAccessKey);
  }
}
