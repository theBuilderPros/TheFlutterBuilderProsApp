class EncryptedWalletSecret {
  const EncryptedWalletSecret({
    required this.salt,
    required this.nonce,
    required this.cipherText,
    required this.mac,
    required this.kdfIterations,
  });

  final String salt;
  final String nonce;
  final String cipherText;
  final String mac;
  final int kdfIterations;

  Map<String, dynamic> toJson() {
    return {
      'salt': salt,
      'nonce': nonce,
      'cipherText': cipherText,
      'mac': mac,
      'kdfIterations': kdfIterations,
    };
  }

  factory EncryptedWalletSecret.fromJson(Map<String, dynamic> json) {
    return EncryptedWalletSecret(
      salt: json['salt'] as String? ?? '',
      nonce: json['nonce'] as String? ?? '',
      cipherText: json['cipherText'] as String? ?? '',
      mac: json['mac'] as String? ?? '',
      kdfIterations: json['kdfIterations'] as int? ?? 200000,
    );
  }
}
