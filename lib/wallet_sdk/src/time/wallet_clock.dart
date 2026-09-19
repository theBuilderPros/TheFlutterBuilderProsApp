abstract interface class WalletClock {
  DateTime nowUtc();
}

final class SystemWalletClock implements WalletClock {
  const SystemWalletClock();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();
}

final class CallbackWalletClock implements WalletClock {
  const CallbackWalletClock(this._now);

  final DateTime Function() _now;

  @override
  DateTime nowUtc() => _now().toUtc();
}
