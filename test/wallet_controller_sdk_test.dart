import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:the_builder_studio/app/core/config/loyalty_system_config.dart';
import 'package:the_builder_studio/app/features/wallet/controller/wallet_controller.dart';
import 'package:the_builder_studio/app/features/wallet/model/customer_wallet_access.dart';
import 'package:the_builder_studio/app/features/wallet/model/wallet_transaction_history_model.dart';
import 'package:the_builder_studio/app/features/wallet/service/customer_access_import_service.dart';
import 'package:the_builder_studio/app/features/wallet/service/recipient_validation_service.dart';
import 'package:the_builder_studio/app/features/wallet/service/wallet_activation_storage_service.dart';
import 'package:the_builder_studio/app/features/wallet/service/wallet_transaction_history_service.dart';
import 'package:the_builder_studio/app/features/wallet/service/wallet_unlock_service.dart';
import 'package:the_builder_studio/app/features/wallet/utility/loyalty_points_result.dart';
import 'package:the_builder_studio/app/features/wallet/utility/loyalty_points_sdk.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  test('refreshWalletBalance delegates to LoyaltyPointsSdk', () async {
    final sdk = _FakeLoyaltyPointsSdk(
      balanceResult: const LoyaltyBalanceResult(
        balance: '125.50',
        assetCode: 'SKINO',
      ),
    );
    final controller = _buildController(sdk);

    await controller.refreshWalletBalance();

    expect(sdk.checkBalanceCalls, 1);
    expect(controller.currentBalance.value, '125.50');

    controller.onClose();
  });

  test('confirmSend records SDK failures without real network calls', () async {
    const failure = LoyaltyPointsFailure(
      code: 'invalidRecipient',
      message: 'Recipient cannot receive points.',
    );
    final sdk = _FakeLoyaltyPointsSdk(sendFailure: failure);
    final historyService = _FakeWalletTransactionHistoryService();
    final controller = _buildController(sdk, historyService: historyService);
    controller.recipientController.text = _validRecipientPublicKey;
    controller.amountController.text = '25';

    await controller.confirmSend();

    expect(sdk.sentRecipient, _validRecipientPublicKey);
    expect(sdk.sentAmount, '25');
    expect(controller.message.value, failure.message);
    expect(historyService.records, hasLength(1));
    expect(
      historyService.records.single.status,
      WalletTransactionStatus.failed,
    );
    expect(historyService.records.single.errorMessage, failure.message);

    controller.onClose();
  });
}

WalletController _buildController(
  LoyaltyPointsSdk sdk, {
  WalletTransactionHistoryService? historyService,
}) {
  final controller = WalletController(
    importService: CustomerAccessImportService(),
    storageService: WalletActivationStorageService(),
    unlockService: WalletUnlockService(),
    recipientValidationService: RecipientValidationService(),
    historyService: historyService ?? _FakeWalletTransactionHistoryService(),
    loyaltyPointsSdk: sdk,
    enableSnackbars: false,
  );
  controller.config.value = _config;
  controller.walletAccess.value = _walletAccess;
  controller.walletState.value = WalletState.activated;
  return controller;
}

const _config = LoyaltySystemConfig(
  merchantName: 'Skino',
  pointName: 'Quick Pay Points',
  assetCode: 'SKINO',
  totalSupply: 1000000,
  issuerPublicKey: _issuerPublicKey,
  distributorPublicKey: _distributorPublicKey,
  networkName: 'TESTNET',
  horizonUrl: 'https://horizon-testnet.stellar.org',
  nownodeApiKey: 'test-key',
  importSource: 'test',
  packageVersion: 'test',
);

const _walletAccess = CustomerWalletAccess(
  customerName: 'Test Customer',
  customerId: 'C-001',
  phone: '+959000000000',
  publicKey: _senderPublicKey,
  assetCode: 'SKINO',
);

const _senderPublicKey =
    'GAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAWHF';
const _issuerPublicKey =
    'GBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBWHF';
const _distributorPublicKey =
    'GCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCWHF';
const _validRecipientPublicKey =
    'GDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDWHF';

class _FakeLoyaltyPointsSdk implements LoyaltyPointsSdk {
  _FakeLoyaltyPointsSdk({
    this.balanceResult = const LoyaltyBalanceResult(
      balance: '0',
      assetCode: 'SKINO',
    ),
    this.sendFailure,
  });

  final LoyaltyBalanceResult balanceResult;
  final LoyaltyPointsFailure? sendFailure;

  int checkBalanceCalls = 0;
  String? sentRecipient;
  String? sentAmount;

  @override
  Future<LoyaltyBalanceResult> checkBalance() async {
    checkBalanceCalls += 1;
    return balanceResult;
  }

  @override
  Future<LoyaltySendResult> send({
    required String recipient,
    required String amount,
  }) async {
    sentRecipient = recipient;
    sentAmount = amount;
    final failure = sendFailure;
    if (failure != null) {
      throw failure;
    }
    return const LoyaltySendResult(
      transactionHash: 'tx-test',
      updatedBalance: '75',
    );
  }
}

class _FakeWalletTransactionHistoryService
    extends WalletTransactionHistoryService {
  final List<WalletTransactionHistoryModel> records =
      <WalletTransactionHistoryModel>[];

  @override
  Future<List<WalletTransactionHistoryModel>> loadHistory() async {
    return List<WalletTransactionHistoryModel>.of(records);
  }

  @override
  Future<void> saveRecord(WalletTransactionHistoryModel record) async {
    records.insert(0, record);
  }
}
