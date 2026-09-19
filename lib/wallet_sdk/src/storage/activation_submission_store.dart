import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum ActivationSubmissionStatus {
  submitting,
  submitted,
  rejected,
  uncertain,
  verified,
}

final class ActivationSubmissionRecord {
  const ActivationSubmissionRecord({
    required this.responseId,
    required this.transactionHash,
    required this.status,
  });

  final String responseId;
  final String transactionHash;
  final ActivationSubmissionStatus status;

  String encode() => jsonEncode(<String, Object>{
    'response_id': responseId,
    'transaction_hash': transactionHash,
    'status': status.name,
  });

  factory ActivationSubmissionRecord.decode(String value) {
    final Map<String, dynamic> json = jsonDecode(value) as Map<String, dynamic>;
    return ActivationSubmissionRecord(
      responseId: json['response_id'] as String,
      transactionHash: json['transaction_hash'] as String,
      status: ActivationSubmissionStatus.values.byName(
        json['status'] as String,
      ),
    );
  }
}

abstract interface class ActivationSubmissionStore {
  Future<ActivationSubmissionRecord?> read();

  Future<void> write(ActivationSubmissionRecord record);

  Future<void> clear();
}

final class PreferencesActivationSubmissionStore
    implements ActivationSubmissionStore {
  static const String _key = 'rewards.activation.submission.v1';

  @override
  Future<ActivationSubmissionRecord?> read() async {
    final String? raw = (await SharedPreferences.getInstance()).getString(_key);
    return raw == null ? null : ActivationSubmissionRecord.decode(raw);
  }

  @override
  Future<void> write(ActivationSubmissionRecord record) async {
    final bool saved = await (await SharedPreferences.getInstance()).setString(
      _key,
      record.encode(),
    );
    if (!saved) {
      throw StateError('Activation submission state was not persisted.');
    }
  }

  @override
  Future<void> clear() async =>
      (await SharedPreferences.getInstance()).remove(_key);
}
