import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:the_builder_pros/app/constant/routing/app_route.dart';
import 'package:the_builder_pros/app/core/base/base_controller.dart';
import 'package:the_builder_pros/app/features/app_master/service/qr_input_adapter.dart';
import 'package:the_builder_pros/wallet_sdk/wallet_sdk.dart';

enum MockSendOutcome { success, rejected, pending }

class WalletController extends BaseController {
  WalletController(this._walletSdk, {QrInputAdapter? qrInputAdapter})
    : qrInputAdapter = qrInputAdapter ?? QrInputAdapter();

  final WalletSdk _walletSdk;
  final QrInputAdapter qrInputAdapter;

  final TextEditingController builderNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final Rx<MockSendOutcome> sendOutcome = MockSendOutcome.success.obs;
  final RxString activationError = ''.obs;
  final RxBool isPreparingActivation = false.obs;
  final RxBool isCancellingActivation = false.obs;
  final RxString activationCancellationError = ''.obs;
  final Rx<ActivationRequestView?> activationRequest =
      Rx<ActivationRequestView?>(null);
  final Rxn<ActivationReview> activationReview = Rxn<ActivationReview>();
  final RxBool isInspectingActivationResponse = false.obs;
  final RxString activationResponseError = ''.obs;
  final RxBool isApprovingActivation = false.obs;
  final Rxn<ActivationOutcome> activationOutcome = Rxn<ActivationOutcome>();
  final Rx<WalletActivationStatus> activationStatus =
      const WalletActivationStatus.notActivated().obs;

  String get builderName => builderNameController.text.trim();

  String get phoneNumber => phoneController.text.trim();

  @override
  void onReady() {
    super.onReady();
    _restoreActivationRequest();
  }

  Future<void> _restoreActivationRequest() async {
    if (Get.currentRoute != Routes.wallet || isPreparingActivation.value) {
      return;
    }
    try {
      WalletActivationStatus status = await _walletSdk.getActivationStatus();
      if (status.state == WalletActivationState.pending ||
          status.state == WalletActivationState.uncertain) {
        status = await _walletSdk.reconcileActivation();
      }
      activationStatus.value = status;
      if (status.state == WalletActivationState.active) {
        Get.offAllNamed(Routes.walletOverview);
        return;
      }
      final ActivationRequestView? restored = await _walletSdk
          .restoreActivationRequest();
      if (restored == null || Get.currentRoute != Routes.wallet) {
        return;
      }
      activationRequest.value = restored;
      builderNameController.text = restored.builder.displayName;
      phoneController.text = restored.builder.phone;
      Get.toNamed(Routes.walletActivation);
    } catch (_) {
      // Restoration failures leave the user on the safe not-activated screen.
    }
  }

  Future<void> startActivation() async {
    if (isPreparingActivation.value) {
      return;
    }

    final String name = builderName;
    final String phone = phoneNumber;
    final String? validationMessage = _validateIdentity(name, phone);
    if (validationMessage != null) {
      activationError.value = validationMessage;
      return;
    }

    activationError.value = '';
    isPreparingActivation.value = true;
    try {
      activationRequest.value = await _walletSdk.startActivation(
        BuilderIdentity(displayName: name, phone: phone),
      );
      Get.toNamed(Routes.walletActivation);
    } on WalletSdkException catch (error) {
      activationError.value = error.safeMessage;
    } catch (_) {
      activationError.value =
          "We couldn't prepare your activation request. Try again.";
    } finally {
      isPreparingActivation.value = false;
    }
  }

  Future<void> cancelActivation() async {
    if (isCancellingActivation.value) {
      return;
    }

    activationCancellationError.value = '';
    isCancellingActivation.value = true;
    try {
      await _walletSdk.cancelActivation();
      activationRequest.value = null;
      builderNameController.clear();
      phoneController.clear();
      Get.offAllNamed(Routes.wallet);
    } on WalletSdkException catch (error) {
      activationCancellationError.value = error.safeMessage;
    } catch (_) {
      activationCancellationError.value =
          "We couldn't cancel this activation. Try again.";
    } finally {
      isCancellingActivation.value = false;
    }
  }

  String? _validateIdentity(String name, String phone) {
    if (name.isEmpty || phone.isEmpty) {
      return 'Enter your Builder name and phone number.';
    }
    if (!phone.startsWith('+') || phone.length < 8) {
      return 'Enter a phone number with its country code.';
    }
    return null;
  }

  void openActivationScanner() {
    activationResponseError.value = '';
    Get.toNamed(Routes.walletActivationScan);
  }

  Future<void> importActivationResponse() async {
    if (isInspectingActivationResponse.value) return;
    final QrInputResult result = await qrInputAdapter.importFromGallery();
    if (result.isSuccess) {
      await inspectActivationResponse(result.value!);
    } else if (result.failure != QrInputFailure.cancelled) {
      activationResponseError.value =
          "We couldn't read an activation QR from that image.";
    }
  }

  Future<void> inspectActivationResponse(String value) async {
    if (isInspectingActivationResponse.value) return;
    isInspectingActivationResponse.value = true;
    activationResponseError.value = '';
    try {
      activationReview.value = await _walletSdk.inspectActivationResponse(
        value,
      );
      Get.offNamed(Routes.walletActivationReview);
    } on WalletSdkException catch (error) {
      activationResponseError.value = error.safeMessage;
      if (Get.currentRoute == Routes.walletActivationScan) Get.back<void>();
    } finally {
      isInspectingActivationResponse.value = false;
    }
  }

  Future<void> approveActivation() async {
    final ActivationReview? review = activationReview.value;
    if (review == null || isApprovingActivation.value) return;
    isApprovingActivation.value = true;
    activationResponseError.value = '';
    try {
      activationOutcome.value = await _walletSdk.approveActivation(
        review.responseId,
      );
      if (activationOutcome.value!.state != ActivationOutcomeState.rejected) {
        final WalletActivationStatus status = await _walletSdk
            .reconcileActivation();
        activationStatus.value = status;
        if (status.state == WalletActivationState.active) {
          Get.offAllNamed(Routes.walletOverview);
        } else {
          activationOutcome.value = ActivationOutcome(
            responseId: review.responseId,
            state: status.state == WalletActivationState.failed
                ? ActivationOutcomeState.rejected
                : ActivationOutcomeState.uncertain,
            message: status.message,
          );
        }
      }
    } on WalletSdkException catch (error) {
      activationResponseError.value = error.safeMessage;
    } finally {
      isApprovingActivation.value = false;
    }
  }

  void completeQrActivation() => Get.offAllNamed(Routes.walletOverview);

  void openWalletOverview() => Get.offAllNamed(Routes.walletOverview);

  void openAppMaster() => Get.offAllNamed(Routes.appMaster);

  void openReceive() => Get.toNamed(Routes.walletReceive);

  void openSend() => Get.toNamed(Routes.walletSendScan);

  void openHistory() => Get.toNamed(Routes.walletHistory);

  void openLocked() => Get.toNamed(Routes.walletLocked);

  void openRemoveWallet() => Get.toNamed(Routes.walletRemove);

  void useMockRecipient() => Get.toNamed(Routes.walletSendAmount);

  void reviewMockAmount() => Get.toNamed(Routes.walletSendReview);

  void requestAuthentication({
    required String purpose,
    required String nextRoute,
  }) {
    Get.toNamed(
      Routes.walletAuthentication,
      arguments: <String, String>{'purpose': purpose, 'nextRoute': nextRoute},
    );
  }

  void completeAuthentication() {
    final Object? arguments = Get.arguments;
    final String? nextRoute = arguments is Map
        ? arguments['nextRoute'] as String?
        : null;
    Get.offAllNamed(nextRoute ?? Routes.walletOverview);
  }

  void showOutcome(MockSendOutcome outcome) {
    sendOutcome.value = outcome;
    Get.toNamed(Routes.walletSendOutcome);
  }

  @override
  void onClose() {
    builderNameController.dispose();
    phoneController.dispose();
    amountController.dispose();
    super.onClose();
  }
}
