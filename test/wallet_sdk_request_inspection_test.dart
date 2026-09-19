import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_builder_pros/wallet_sdk/src/default_wallet_sdk.dart';
import 'package:the_builder_pros/wallet_sdk/src/storage/activation_inspection_store.dart';
import 'package:the_builder_pros/wallet_sdk/wallet_sdk.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final DateTime now = DateTime.utc(2026, 9, 19, 12);

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  test('inspects and restores a valid request as a safe review', () async {
    final _MemoryInspectionStore inspectionStore = _MemoryInspectionStore();
    final DefaultWalletSdk builderSdk = DefaultWalletSdk(
      now: () => now,
      random: Random(71),
    );
    final ActivationRequestView request = await builderSdk.startActivation(
      const BuilderIdentity(displayName: 'Aung Builder', phone: '+95929208000'),
    );
    final DefaultWalletSdk appMasterSdk = DefaultWalletSdk(
      now: () => now,
      random: Random(72),
      activationInspectionStore: inspectionStore,
    );

    final ActivationRequestReview review = await appMasterSdk
        .inspectBuilderRequest(request.qrValue);

    expect(review.requestId, request.requestId);
    expect(review.builder.displayName, 'Aung Builder');
    expect(review.builder.phone, '+95929208000');
    expect(review.expiresAt, request.expiresAt);
    expect(review.setupSteps, hasLength(3));
    expect(review.toString(), isNot(contains('activation_address')));
    expect(review.toString(), isNot(contains('device_configuration')));

    final ActivationRequestReview? restored = await appMasterSdk
        .restoreInspectedBuilderRequest();
    expect(restored?.requestId, review.requestId);
  });

  test(
    'rejects malformed, oversized, altered, wrong-environment, and expired requests',
    () async {
      final DefaultWalletSdk builderSdk = DefaultWalletSdk(
        now: () => now,
        random: Random(73),
      );
      final ActivationRequestView request = await builderSdk.startActivation(
        const BuilderIdentity(displayName: 'Maya Chen', phone: '+959111111111'),
      );
      final Map<String, dynamic> altered =
          jsonDecode(request.qrValue) as Map<String, dynamic>;
      ((altered['payload'] as Map<String, dynamic>)['builder']
              as Map<String, dynamic>)['name'] =
          'Changed';
      final Map<String, dynamic> wrongEnvironment =
          jsonDecode(request.qrValue) as Map<String, dynamic>;
      (wrongEnvironment['payload'] as Map<String, dynamic>)['environment'] =
          'production';
      final DefaultWalletSdk sdk = DefaultWalletSdk(
        now: () => now,
        random: Random(74),
        activationInspectionStore: _MemoryInspectionStore(),
      );

      for (final String value in <String>[
        '{bad',
        List<String>.filled(5000, 'x').join(),
        jsonEncode(altered),
        jsonEncode(wrongEnvironment),
      ]) {
        await expectLater(
          sdk.inspectBuilderRequest(value),
          throwsA(
            isA<WalletSdkException>().having(
              (WalletSdkException error) => error.code,
              'code',
              WalletSdkFailureCode.invalidActivationRequest,
            ),
          ),
        );
      }

      final DefaultWalletSdk expiredSdk = DefaultWalletSdk(
        now: () => now.add(const Duration(minutes: 16)),
        random: Random(75),
        activationInspectionStore: _MemoryInspectionStore(),
      );
      await expectLater(
        expiredSdk.inspectBuilderRequest(request.qrValue),
        throwsA(
          isA<WalletSdkException>().having(
            (WalletSdkException error) => error.code,
            'code',
            WalletSdkFailureCode.activationRequestExpired,
          ),
        ),
      );
    },
  );

  test('rejects a consumed request', () async {
    final DefaultWalletSdk builderSdk = DefaultWalletSdk(
      now: () => now,
      random: Random(76),
    );
    final ActivationRequestView request = await builderSdk.startActivation(
      const BuilderIdentity(displayName: 'Noah Lee', phone: '+959222222222'),
    );
    final _MemoryInspectionStore store = _MemoryInspectionStore();
    await store.markConsumed(request.requestId);
    final DefaultWalletSdk appMasterSdk = DefaultWalletSdk(
      now: () => now,
      random: Random(77),
      activationInspectionStore: store,
    );

    await expectLater(
      appMasterSdk.inspectBuilderRequest(request.qrValue),
      throwsA(
        isA<WalletSdkException>().having(
          (WalletSdkException error) => error.code,
          'code',
          WalletSdkFailureCode.activationRequestAlreadyUsed,
        ),
      ),
    );
  });
}

final class _MemoryInspectionStore implements ActivationInspectionStore {
  String? pending;
  String? pendingResponse;
  final Set<String> consumed = <String>{};

  @override
  Future<void> clearPendingRequest() async => pending = null;

  @override
  Future<String?> readPendingResponse() async => pendingResponse;

  @override
  Future<void> savePendingResponse(String qrValue) async =>
      pendingResponse = qrValue;

  @override
  Future<bool> isConsumed(String requestId) async =>
      consumed.contains(requestId);

  @override
  Future<void> markConsumed(String requestId) async => consumed.add(requestId);

  @override
  Future<String?> readPendingRequest() async => pending;

  @override
  Future<void> savePendingRequest(String qrValue) async => pending = qrValue;
}
