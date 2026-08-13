import 'dart:convert';

import 'package:the_builder_studio/app/features/wallet/model/wallet_transaction_history_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalletTransactionHistoryService {
  static const String _historyKey = 'builder_studio.wallet.transaction_history';

  Future<List<WalletTransactionHistoryModel>> loadHistory() async {
    final preferences = await SharedPreferences.getInstance();
    final encodedHistory = preferences.getString(_historyKey);
    if (encodedHistory == null || encodedHistory.isEmpty) {
      return <WalletTransactionHistoryModel>[];
    }

    try {
      final decodedHistory = jsonDecode(encodedHistory);
      if (decodedHistory is! List) {
        await clearHistory();
        return <WalletTransactionHistoryModel>[];
      }

      return decodedHistory
          .map(
            (item) => WalletTransactionHistoryModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (_) {
      await clearHistory();
      return <WalletTransactionHistoryModel>[];
    }
  }

  Future<void> saveRecord(WalletTransactionHistoryModel record) async {
    final records = await loadHistory();
    records.insert(0, record);
    final cappedRecords = records
        .take(100)
        .map((item) => item.toJson())
        .toList();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_historyKey, jsonEncode(cappedRecords));
  }

  Future<void> clearHistory() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_historyKey);
  }
}
