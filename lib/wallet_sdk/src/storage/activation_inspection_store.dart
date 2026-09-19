import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class ActivationInspectionStore {
  Future<String?> readPendingRequest();

  Future<void> savePendingRequest(String qrValue);

  Future<void> clearPendingRequest();

  Future<void> savePendingResponse(String qrValue);

  Future<String?> readPendingResponse();

  Future<bool> isConsumed(String requestId);

  Future<void> markConsumed(String requestId);
}

final class ProtectedActivationInspectionStore
    implements ActivationInspectionStore {
  ProtectedActivationInspectionStore({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const String _pendingKey = 'rewards.app_master.inspection.pending.v1';
  static const String _consumedKey =
      'rewards.app_master.inspection.consumed.v1';
  static const String _pendingResponseKey =
      'rewards.builder.inspection.pending_response.v1';
  static const int _maximumConsumedIds = 200;

  final FlutterSecureStorage _secureStorage;

  @override
  Future<String?> readPendingRequest() => _secureStorage.read(key: _pendingKey);

  @override
  Future<void> savePendingRequest(String qrValue) =>
      _secureStorage.write(key: _pendingKey, value: qrValue);

  @override
  Future<void> clearPendingRequest() => _secureStorage.delete(key: _pendingKey);

  @override
  Future<void> savePendingResponse(String qrValue) =>
      _secureStorage.write(key: _pendingResponseKey, value: qrValue);

  @override
  Future<String?> readPendingResponse() =>
      _secureStorage.read(key: _pendingResponseKey);

  @override
  Future<bool> isConsumed(String requestId) async =>
      (await _readConsumed()).contains(requestId);

  @override
  Future<void> markConsumed(String requestId) async {
    final List<String> ids = await _readConsumed();
    ids.remove(requestId);
    ids.add(requestId);
    if (ids.length > _maximumConsumedIds) {
      ids.removeRange(0, ids.length - _maximumConsumedIds);
    }
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final bool saved = await preferences.setString(
      _consumedKey,
      jsonEncode(ids),
    );
    if (!saved) {
      throw StateError('Consumed request state was not persisted.');
    }
  }

  Future<List<String>> _readConsumed() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String? raw = preferences.getString(_consumedKey);
    if (raw == null) {
      return <String>[];
    }
    final Object? decoded = jsonDecode(raw);
    if (decoded is! List<dynamic> || decoded.any((value) => value is! String)) {
      throw const FormatException('Invalid consumed request state.');
    }
    return decoded.cast<String>();
  }
}
