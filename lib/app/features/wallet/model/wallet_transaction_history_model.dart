enum WalletTransactionStatus { success, failed }

class WalletTransactionHistoryModel {
  const WalletTransactionHistoryModel({
    required this.id,
    required this.timestamp,
    required this.senderPublicKey,
    required this.recipientPublicKey,
    required this.amount,
    required this.assetCode,
    required this.assetIssuer,
    required this.network,
    required this.status,
    this.transactionHash,
    this.errorMessage,
  });

  final String id;
  final DateTime timestamp;
  final String senderPublicKey;
  final String recipientPublicKey;
  final String amount;
  final String assetCode;
  final String assetIssuer;
  final String network;
  final WalletTransactionStatus status;
  final String? transactionHash;
  final String? errorMessage;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'senderPublicKey': senderPublicKey,
      'recipientPublicKey': recipientPublicKey,
      'amount': amount,
      'assetCode': assetCode,
      'assetIssuer': assetIssuer,
      'network': network,
      'status': status.name,
      'transactionHash': transactionHash,
      'errorMessage': errorMessage,
    };
  }

  factory WalletTransactionHistoryModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionHistoryModel(
      id: json['id'] as String? ?? '',
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      senderPublicKey: json['senderPublicKey'] as String? ?? '',
      recipientPublicKey: json['recipientPublicKey'] as String? ?? '',
      amount: json['amount'] as String? ?? '',
      assetCode: json['assetCode'] as String? ?? '',
      assetIssuer: json['assetIssuer'] as String? ?? '',
      network: json['network'] as String? ?? '',
      status: (json['status'] as String? ?? '') == 'success'
          ? WalletTransactionStatus.success
          : WalletTransactionStatus.failed,
      transactionHash: json['transactionHash'] as String?,
      errorMessage: json['errorMessage'] as String?,
    );
  }
}
