import 'dart:math';

final class ActivationTokenGenerator {
  ActivationTokenGenerator({Random? random})
    : _random = random ?? Random.secure();

  static const String _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  final Random _random;

  String createRequestId() {
    final String token = createToken(6);
    return 'ACT-${token.substring(0, 4)}-${token.substring(4)}';
  }

  String createToken(int length) => List<String>.generate(
    length,
    (_) => _alphabet[_random.nextInt(_alphabet.length)],
    growable: false,
  ).join();
}
