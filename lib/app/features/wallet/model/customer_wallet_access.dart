class CustomerWalletAccess {
  const CustomerWalletAccess({
    required this.customerName,
    required this.customerId,
    required this.phone,
    required this.publicKey,
    required this.assetCode,
    this.secret,
    this.recoveryPhrase,
    this.derivationPath,
  });

  final String customerName;
  final String customerId;
  final String phone;
  final String publicKey;
  final String assetCode;
  final String? secret;
  final String? recoveryPhrase;
  final String? derivationPath;

  bool get hasPublicWallet => publicKey.isNotEmpty;
  bool get hasSecret => secret != null && secret!.isNotEmpty;

  Map<String, dynamic> toPersistedJson() {
    return {
      'customerName': customerName,
      'customerId': customerId,
      'phone': phone,
      'publicKey': publicKey,
      'assetCode': assetCode,
    };
  }

  factory CustomerWalletAccess.fromPersistedJson(Map<String, dynamic> json) {
    return CustomerWalletAccess(
      customerName: json['customerName'] as String? ?? '',
      customerId: json['customerId'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      publicKey: json['publicKey'] as String? ?? '',
      assetCode: json['assetCode'] as String? ?? '',
    );
  }
}
