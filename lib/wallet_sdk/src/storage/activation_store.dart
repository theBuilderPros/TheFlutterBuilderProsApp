import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

final class PendingActivationRecord {
  const PendingActivationRecord({
    required this.requestId,
    required this.qrValue,
    required this.expiresAt,
    required this.credentialKey,
    required this.builderName,
    required this.builderPhone,
  });

  final String requestId;
  final String qrValue;
  final DateTime expiresAt;
  final String credentialKey;
  final String builderName;
  final String builderPhone;

  Map<String, String> toJson() => <String, String>{
    'request_id': requestId,
    'qr_value': qrValue,
    'expires_at': expiresAt.toIso8601String(),
    'secure_key': credentialKey,
    'builder_name': builderName,
    'builder_phone': builderPhone,
  };

  factory PendingActivationRecord.fromJson(Map<String, dynamic> json) =>
      PendingActivationRecord(
        requestId: json['request_id'] as String,
        qrValue: json['qr_value'] as String,
        expiresAt: DateTime.parse(json['expires_at'] as String).toUtc(),
        credentialKey: json['secure_key'] as String,
        builderName: json['builder_name'] as String,
        builderPhone: json['builder_phone'] as String,
      );
}

abstract interface class ActivationStore {
  Future<PendingActivationRecord?> read();

  Future<void> write(PendingActivationRecord record);

  Future<void> clear();
}

final class PreferencesActivationStore implements ActivationStore {
  static const String preferenceKey = 'rewards.activation.pending.v2';
  static const String legacyPreferenceKey = 'rewards.activation.pending.v1';

  @override
  Future<PendingActivationRecord?> read() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String? raw =
        preferences.getString(preferenceKey) ??
        preferences.getString(legacyPreferenceKey);
    if (raw == null) {
      return null;
    }
    return PendingActivationRecord.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> write(PendingActivationRecord record) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final bool saved = await preferences.setString(
      preferenceKey,
      jsonEncode(record.toJson()),
    );
    if (!saved) {
      throw StateError('Pending activation request was not persisted.');
    }
  }

  @override
  Future<void> clear() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.remove(preferenceKey);
    await preferences.remove(legacyPreferenceKey);
  }
}
