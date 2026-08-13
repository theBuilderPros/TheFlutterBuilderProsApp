import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:the_builder_studio/app/constant/resources/app_string.dart';
import 'package:the_builder_studio/app/constant/routing/app_route.dart';
import 'package:the_builder_studio/app/core/base/base_controller.dart';
import 'package:the_builder_studio/app/core/config/loyalty_system_config.dart';
import 'package:the_builder_studio/app/features/wallet/model/customer_wallet_access.dart';
import 'package:the_builder_studio/app/features/wallet/model/wallet_transaction_history_model.dart';
import 'package:the_builder_studio/app/features/wallet/service/customer_access_import_service.dart';
import 'package:the_builder_studio/app/features/wallet/service/recipient_validation_service.dart';
import 'package:the_builder_studio/app/features/wallet/service/wallet_activation_storage_service.dart';
import 'package:the_builder_studio/app/features/wallet/service/wallet_transaction_history_service.dart';
import 'package:the_builder_studio/app/features/wallet/service/wallet_unlock_service.dart';
import 'package:the_builder_studio/app/features/wallet/utility/loyalty_points_result.dart';
import 'package:the_builder_studio/app/features/wallet/utility/loyalty_points_sdk.dart';

enum WalletState { loading, configMissing, ready, activated, error }

class WalletController extends BaseController {
  WalletController({
    CustomerAccessImportService? importService,
    WalletActivationStorageService? storageService,
    WalletUnlockService? unlockService,
    RecipientValidationService? recipientValidationService,
    WalletTransactionHistoryService? historyService,
    LoyaltyPointsSdk? loyaltyPointsSdk,
    bool enableSnackbars = true,
  }) : _importService =
           importService ?? Get.find<CustomerAccessImportService>(),
       _storageService =
           storageService ?? Get.find<WalletActivationStorageService>(),
       _unlockService = unlockService ?? Get.find<WalletUnlockService>(),
       _recipientValidationService =
           recipientValidationService ?? Get.find<RecipientValidationService>(),
       _historyService =
           historyService ?? Get.find<WalletTransactionHistoryService>(),
       _loyaltyPointsSdk = loyaltyPointsSdk ?? Get.find<LoyaltyPointsSdk>(),
       _enableSnackbars = enableSnackbars;

  final CustomerAccessImportService _importService;
  final WalletActivationStorageService _storageService;
  final WalletUnlockService _unlockService;
  final RecipientValidationService _recipientValidationService;
  final WalletTransactionHistoryService _historyService;
  final LoyaltyPointsSdk _loyaltyPointsSdk;
  final bool _enableSnackbars;

  final Rx<WalletState> walletState = WalletState.loading.obs;
  final Rxn<LoyaltySystemConfig> config = Rxn<LoyaltySystemConfig>();
  final Rxn<CustomerWalletAccess> walletAccess = Rxn<CustomerWalletAccess>();
  final RxString currentBalance = '0'.obs;
  final RxString scannedRecipient = ''.obs;
  final RxBool isRecipientValid = false.obs;
  final RxBool isRecipientValidating = false.obs;
  final RxString recipientValidationMessage = ''.obs;
  final RxBool isSubmittingSend = false.obs;
  final RxBool hasEncryptedSecret = false.obs;
  final RxInt rewardsMode = 0.obs;
  final RxList<WalletTransactionHistoryModel> history =
      <WalletTransactionHistoryModel>[].obs;
  final TextEditingController recipientController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  String get merchantName =>
      config.value?.merchantName ?? AppString.walletTitle;

  String get pointName =>
      config.value?.pointName ?? AppString.walletDefaultPointName;

  String get assetCode => config.value?.assetCode ?? '';
  String get assetIssuer => config.value?.issuerPublicKey ?? '';
  String get networkName => config.value?.networkName ?? '';
  bool get isWalletUnlocked => _unlockService.isUnlocked;

  bool get canContinueToReview {
    final amount = double.tryParse(amountController.text.trim());
    return isRecipientValid.value && amount != null && amount > 0;
  }

  @override
  void onInit() {
    super.onInit();
    loadConfig();
  }

  Future<void> loadConfig() async {
    walletState.value = WalletState.loading;
    showMessage('');

    try {
      config.value = await LoyaltySystemConfig.loadLocal();
      await _restoreEncryptedSecretState();
      await refreshHistory();
      await _restoreActivatedWallet();
    } on LoyaltySystemConfigMissing catch (error) {
      walletState.value = WalletState.configMissing;
      showMessage(error.message);
    } on LoyaltySystemConfigFailure catch (error) {
      walletState.value = WalletState.error;
      showMessage(error.message);
    } catch (error) {
      walletState.value = WalletState.error;
      showMessage(error.toString());
    }
  }

  Future<void> activateWallet() async {
    final activeConfig = config.value;
    if (activeConfig == null) {
      await loadConfig();
      return;
    }

    showLoading();
    showMessage(AppString.walletSelectingAccessZipMessage);

    try {
      final importedAccess = await _importService.pickAndImportZip();
      if (importedAccess == null) {
        showMessage(AppString.walletAccessSelectionCanceled);
        return;
      }

      walletAccess.value = importedAccess;
      await _storeImportedSecret(importedAccess);
      await _storageService.saveWalletAccess(importedAccess);
      showMessage('');
      await refreshWalletBalance();
      walletState.value = WalletState.activated;
    } on CustomerAccessImportFailure catch (error) {
      walletState.value = WalletState.error;
      showMessage(error.message);
    } catch (error) {
      walletState.value = WalletState.error;
      showMessage(error.toString());
    } finally {
      hideLoading();
    }
  }

  Future<void> _restoreActivatedWallet() async {
    final restoredAccess = await _storageService.restoreWalletAccess();
    if (restoredAccess == null) {
      walletState.value = WalletState.ready;
      return;
    }

    walletAccess.value = restoredAccess;
    walletState.value = WalletState.activated;
    await refreshWalletBalance();
  }

  Future<void> _restoreEncryptedSecretState() async {
    hasEncryptedSecret.value =
        await _storageService.restoreEncryptedSecret() != null;
  }

  Future<void> _storeImportedSecret(CustomerWalletAccess importedAccess) async {
    final secret = importedAccess.secret;
    if (secret == null || secret.isEmpty) {
      hasEncryptedSecret.value = false;
      showMessage(AppString.walletSecretMissingMessage);
      return;
    }

    final passcode = await _requestPasscode(
      message: AppString.walletCreatePasscodeMessage,
      confirmLabel: AppString.walletContinue,
    );
    if (passcode == null || passcode.isEmpty) {
      throw const CustomerAccessImportFailure(
        'Wallet activation needs a passcode to encrypt the customer secret.',
      );
    }

    final encryptedSecret = await _unlockService.encryptSecret(
      secret: secret,
      passcode: passcode,
    );
    await _storageService.saveEncryptedSecret(encryptedSecret);
    hasEncryptedSecret.value = true;
    await _unlockService.unlock(
      encryptedSecret: encryptedSecret,
      passcode: passcode,
    );
  }

  Future<void> refreshWalletBalance() async {
    final activeConfig = config.value;
    final activeAccess = walletAccess.value;
    if (activeConfig == null || activeAccess == null) {
      return;
    }

    try {
      final result = await _loyaltyPointsSdk.checkBalance();
      currentBalance.value = result.balance;
    } on LoyaltyPointsFailure catch (error) {
      showMessage(error.message);
    } catch (error) {
      showMessage(error.toString());
    }
  }

  void copyPublicKey() {
    final publicKey = walletAccess.value?.publicKey ?? '';
    if (publicKey.isEmpty) {
      return;
    }

    Clipboard.setData(ClipboardData(text: publicKey));
    showMessage(AppString.walletPublicKeyCopied);
  }

  Future<void> applyScannedRecipient(String value) async {
    final normalizedValue = normalizeWalletPublicKey(value) ?? '';
    if (normalizedValue.isEmpty) {
      showMessage(AppString.walletInvalidQr);
      return;
    }

    recipientController.text = normalizedValue;
    scannedRecipient.value = normalizedValue;
    showMessage(AppString.walletRecipientCaptured);
    await validateRecipient();
    if (isRecipientValid.value) {
      Get.offNamed(Routes.walletSend);
    }
  }

  String? normalizeWalletPublicKey(String rawValue) {
    final match = RegExp(
      r'G[A-Z2-7]{55}',
      caseSensitive: false,
    ).firstMatch(rawValue.trim());
    return match?.group(0)?.toUpperCase();
  }

  Future<void> validateRecipient() async {
    final activeConfig = config.value;
    final recipient = recipientController.text.trim();
    isRecipientValid.value = false;
    if (activeConfig == null || recipient.isEmpty) {
      return;
    }

    isRecipientValidating.value = true;
    recipientValidationMessage.value = AppString.walletValidatingRecipient;
    try {
      final result = await _recipientValidationService.validate(
        config: activeConfig,
        recipientPublicKey: recipient,
      );
      isRecipientValid.value = result.isValid;
      recipientValidationMessage.value = result.message;
    } catch (_) {
      recipientValidationMessage.value =
          'Could not validate recipient. Check the network and try again.';
    } finally {
      isRecipientValidating.value = false;
    }
  }

  Future<void> unlockWalletForSend() async {
    final encryptedSecret = await _storageService.restoreEncryptedSecret();
    if (encryptedSecret == null) {
      showMessage(AppString.walletSecretMissingMessage);
      _showWalletSnackbar(
        AppString.walletSendFailure,
        AppString.walletSecretMissingMessage,
      );
      return;
    }

    final passcode = await _requestPasscode(
      message: AppString.walletUnlockPasscodeMessage,
      confirmLabel: AppString.walletUnlockButton,
    );
    if (passcode == null || passcode.isEmpty) {
      return;
    }

    try {
      await _unlockService.unlock(
        encryptedSecret: encryptedSecret,
        passcode: passcode,
      );
      showMessage('');
    } on WalletUnlockFailure catch (error) {
      showMessage(error.message);
      _showWalletSnackbar(AppString.walletSendFailure, error.message);
    }
  }

  void openSendScan() {
    if (walletAccess.value == null) {
      showMessage(AppString.walletActivateFirstMessage);
      return;
    }
    _resetSendState();
    Get.toNamed(Routes.walletSendScan);
  }

  void openReceive() => Get.toNamed(Routes.walletReceive);

  void openHistory() {
    refreshHistory();
    Get.toNamed(Routes.walletHistory);
  }

  Future<void> continueToReview() async {
    await validateRecipient();
    final amount = double.tryParse(amountController.text.trim());
    if (!isRecipientValid.value) {
      return;
    }
    if (amount == null || amount <= 0) {
      showMessage(AppString.walletInvalidAmount);
      return;
    }
    Get.toNamed(Routes.walletSendReview);
  }

  Future<void> confirmSend() async {
    final activeWallet = walletAccess.value;
    final amount = amountController.text.trim();
    final recipient = recipientController.text.trim();
    if (config.value == null || activeWallet == null) {
      return;
    }

    isSubmittingSend.value = true;
    String? transactionHash;
    String? errorMessage;
    var status = WalletTransactionStatus.failed;
    try {
      final result = await _loyaltyPointsSdk.send(
        recipient: recipient,
        amount: amount,
      );
      transactionHash = result.transactionHash;
      currentBalance.value = result.updatedBalance;
      status = WalletTransactionStatus.success;
      showMessage(AppString.walletSendSuccess);
      _showWalletSnackbar(
        AppString.walletSendTitle,
        AppString.walletSendSuccess,
      );
    } on LoyaltyPointsFailure catch (error) {
      errorMessage = error.message;
      showMessage(error.message);
      _showWalletSnackbar(AppString.walletSendFailure, error.message);
      if (error.code == 'walletLocked') {
        await unlockWalletForSend();
      }
    } catch (_) {
      errorMessage = AppString.walletSendFailure;
      showMessage(errorMessage);
      _showWalletSnackbar(AppString.walletSendFailure, errorMessage);
    } finally {
      await _saveHistoryRecord(
        status: status,
        transactionHash: transactionHash,
        errorMessage: errorMessage,
      );
      isSubmittingSend.value = false;
    }

    if (status == WalletTransactionStatus.success) {
      _resetSendState();
      Get.until((route) => route.settings.name == Routes.wallet);
    }
  }

  Future<void> refreshHistory() async {
    history.assignAll(await _historyService.loadHistory());
  }

  Future<void> _saveHistoryRecord({
    required WalletTransactionStatus status,
    String? transactionHash,
    String? errorMessage,
  }) async {
    final activeConfig = config.value;
    final activeWallet = walletAccess.value;
    if (activeConfig == null || activeWallet == null) {
      return;
    }
    final record = WalletTransactionHistoryModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      senderPublicKey: activeWallet.publicKey,
      recipientPublicKey: recipientController.text.trim(),
      amount: amountController.text.trim(),
      assetCode: activeConfig.assetCode,
      assetIssuer: activeConfig.issuerPublicKey,
      network: activeConfig.networkName,
      status: status,
      transactionHash: transactionHash,
      errorMessage: errorMessage,
    );
    await _historyService.saveRecord(record);
    await refreshHistory();
  }

  void _showWalletSnackbar(String title, String message) {
    if (!_enableSnackbars) {
      return;
    }
    Get.snackbar(title, message);
  }

  Future<String?> _requestPasscode({
    required String message,
    required String confirmLabel,
  }) async {
    return Get.dialog<String>(
      _WalletPasscodeDialog(message: message, confirmLabel: confirmLabel),
      barrierDismissible: false,
    );
  }

  void _resetSendState() {
    recipientController.clear();
    amountController.clear();
    scannedRecipient.value = '';
    isRecipientValid.value = false;
    recipientValidationMessage.value = '';
  }

  @override
  void onClose() {
    recipientController.dispose();
    amountController.dispose();
    super.onClose();
  }
}

class _WalletPasscodeDialog extends StatefulWidget {
  const _WalletPasscodeDialog({
    required this.message,
    required this.confirmLabel,
  });

  final String message;
  final String confirmLabel;

  @override
  State<_WalletPasscodeDialog> createState() => _WalletPasscodeDialogState();
}

class _WalletPasscodeDialogState extends State<_WalletPasscodeDialog> {
  final TextEditingController _passcodeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppString.walletPasscodeTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.message),
          const SizedBox(height: 12),
          TextField(
            controller: _passcodeController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: AppString.walletPasscodeLabel,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back<String>(),
          child: const Text(AppString.walletCancel),
        ),
        FilledButton(
          onPressed: () =>
              Get.back<String>(result: _passcodeController.text.trim()),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _passcodeController.dispose();
    super.dispose();
  }
}
