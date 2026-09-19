import 'package:get/get.dart';
import 'package:the_builder_pros/app/constant/routing/app_route.dart';
import 'package:the_builder_pros/app/core/base/base_controller.dart';
import 'package:the_builder_pros/app/features/app_master/service/qr_input_adapter.dart';
import 'package:the_builder_pros/wallet_sdk/wallet_sdk.dart';

class MockBuilderRewards {
  const MockBuilderRewards({
    required this.name,
    required this.rewardsBalance,
    required this.status,
    required this.lastChecked,
  });

  final String name;
  final String rewardsBalance;
  final String status;
  final String lastChecked;
}

class AppMasterController extends BaseController {
  AppMasterController(this._walletSdk, {QrInputAdapter? qrInputAdapter})
    : qrInputAdapter = qrInputAdapter ?? QrInputAdapter();

  final WalletSdk _walletSdk;
  final QrInputAdapter qrInputAdapter;

  String nowNodesEndpoint = 'https://xlm.nownodes.io';
  String nowNodesApiKey = '';
  final Rx<ProviderEnvironment> providerEnvironment =
      ProviderEnvironment.production.obs;
  final Rx<ProviderConfigurationStatus> providerConfigurationStatus =
      const ProviderConfigurationStatus.notConfigured().obs;
  final RxBool isSavingProviderConfiguration = false.obs;
  final RxString providerConfigurationError = ''.obs;
  final RxInt providerKeyFieldRevision = 0.obs;
  String distributorSecret = '';
  final Rx<DistributorAuthorityStatus> distributorAuthorityStatus =
      const DistributorAuthorityStatus.notConfigured().obs;
  final RxBool isSavingDistributorAuthority = false.obs;
  final RxString distributorAuthorityError = ''.obs;
  final RxInt distributorSecretFieldRevision = 0.obs;
  final Rxn<AppMasterOverview> appMasterOverview = Rxn<AppMasterOverview>();
  final RxBool isRefreshingOverview = false.obs;
  final RxString overviewError = ''.obs;
  final RxBool isImportingActivationRequest = false.obs;
  final RxString qrInputError = ''.obs;
  final RxBool isInspectingActivationRequest = false.obs;
  final Rxn<ActivationRequestReview> activationRequestReview =
      Rxn<ActivationRequestReview>();
  final Rxn<ActivationResponseView> activationResponse =
      Rxn<ActivationResponseView>();
  final RxBool isCreatingActivationResponse = false.obs;
  final RxString activationResponseError = ''.obs;
  String? _pendingActivationRequestValue;

  String? get pendingActivationRequestValue => _pendingActivationRequestValue;

  static const List<MockBuilderRewards> builders = <MockBuilderRewards>[
    MockBuilderRewards(
      name: 'Jordan Rivers',
      rewardsBalance: '1,250 BUILDER',
      status: 'Rewards ready',
      lastChecked: 'Just now',
    ),
    MockBuilderRewards(
      name: 'Maya Chen',
      rewardsBalance: '840 BUILDER',
      status: 'Rewards ready',
      lastChecked: '2 minutes ago',
    ),
    MockBuilderRewards(
      name: 'Noah Williams',
      rewardsBalance: '0 BUILDER',
      status: 'Pending activation',
      lastChecked: 'Waiting for approval',
    ),
  ];

  @override
  void onReady() {
    super.onReady();
    restoreProviderConfigurationStatus();
    restoreDistributorAuthorityStatus();
    restoreActivationRequestReview();
    refreshOverview();
  }

  Future<void> restoreProviderConfigurationStatus() async {
    try {
      final ProviderConfigurationStatus status = await _walletSdk
          .getProviderConfigurationStatus();
      providerConfigurationStatus.value = status;
      if (status.environment != null) {
        providerEnvironment.value = status.environment!;
      }
    } catch (_) {
      providerConfigurationError.value =
          "We couldn't load the service status. Try again.";
    }
  }

  Future<void> saveProviderConfiguration() async {
    if (isSavingProviderConfiguration.value) {
      return;
    }

    providerConfigurationError.value = '';
    isSavingProviderConfiguration.value = true;
    try {
      final ProviderConfigurationOutcome outcome = await _walletSdk
          .saveAppMasterProviderConfiguration(
            ProviderConfigurationInput(
              endpoint: nowNodesEndpoint.trim(),
              apiKey: nowNodesApiKey.trim(),
              environment: providerEnvironment.value,
              version: (providerConfigurationStatus.value.version ?? 0) + 1,
            ),
          );
      providerConfigurationStatus.value = outcome.status;
    } on WalletSdkException catch (error) {
      providerConfigurationError.value = error.safeMessage;
    } catch (_) {
      providerConfigurationError.value =
          "We couldn't save these settings. Try again.";
    } finally {
      nowNodesApiKey = '';
      providerKeyFieldRevision.value++;
      isSavingProviderConfiguration.value = false;
    }
  }

  Future<void> restoreDistributorAuthorityStatus() async {
    distributorAuthorityStatus.value = await _walletSdk
        .getDistributorAuthorityStatus();
  }

  Future<void> importDistributorAuthority() async {
    if (isSavingDistributorAuthority.value) {
      return;
    }
    distributorAuthorityError.value = '';
    isSavingDistributorAuthority.value = true;
    try {
      distributorAuthorityStatus.value = await _walletSdk
          .importDistributorSecret(distributorSecret);
    } on WalletSdkException catch (error) {
      distributorAuthorityError.value = error.safeMessage;
    } catch (_) {
      distributorAuthorityError.value =
          "We couldn't import the distributor account. Try again.";
    } finally {
      distributorSecret = '';
      distributorSecretFieldRevision.value++;
      isSavingDistributorAuthority.value = false;
    }
  }

  Future<void> removeDistributorAuthority() async {
    try {
      await _walletSdk.removeDistributorAuthority();
      distributorAuthorityStatus.value =
          const DistributorAuthorityStatus.notConfigured();
      distributorAuthorityError.value = '';
    } on WalletSdkException catch (error) {
      distributorAuthorityError.value = error.safeMessage;
    }
  }

  Future<void> refreshOverview() async {
    if (isRefreshingOverview.value) {
      return;
    }
    isRefreshingOverview.value = true;
    overviewError.value = '';
    try {
      appMasterOverview.value = await _walletSdk.getAppMasterOverview();
    } on WalletSdkException catch (error) {
      overviewError.value = error.safeMessage;
    } catch (_) {
      overviewError.value = "We couldn't refresh App Master status. Try again.";
    } finally {
      isRefreshingOverview.value = false;
    }
  }

  void openBuilderWallet() => Get.offAllNamed(Routes.wallet);

  void openAdvanced() => Get.offAllNamed(Routes.appMasterAdvanced);

  void openActivationReview() => Get.toNamed(Routes.appMasterActivationReview);

  void openActivationScanner() {
    qrInputError.value = '';
    Get.toNamed(Routes.appMasterActivationScan);
  }

  Future<void> importActivationRequest() async {
    if (isImportingActivationRequest.value) {
      return;
    }
    qrInputError.value = '';
    isImportingActivationRequest.value = true;
    try {
      final QrInputResult result = await qrInputAdapter.importFromGallery();
      if (result.isSuccess) {
        await acceptActivationRequest(result.value!);
      } else {
        handleQrFailure(result.failure!);
      }
    } finally {
      isImportingActivationRequest.value = false;
    }
  }

  Future<void> acceptActivationRequest(String opaqueValue) async {
    if (isInspectingActivationRequest.value) {
      return;
    }
    _pendingActivationRequestValue = opaqueValue;
    qrInputError.value = '';
    isInspectingActivationRequest.value = true;
    try {
      activationRequestReview.value = await _walletSdk.inspectBuilderRequest(
        opaqueValue,
      );
      Get.offNamed(Routes.appMasterActivationReview);
    } on WalletSdkException catch (error) {
      qrInputError.value = error.safeMessage;
      if (Get.currentRoute == Routes.appMasterActivationScan) {
        Get.back<void>();
      }
    } catch (_) {
      qrInputError.value =
          "We couldn't inspect this activation request. Try again.";
      if (Get.currentRoute == Routes.appMasterActivationScan) {
        Get.back<void>();
      }
    } finally {
      _pendingActivationRequestValue = null;
      isInspectingActivationRequest.value = false;
    }
  }

  Future<void> restoreActivationRequestReview() async {
    activationRequestReview.value = await _walletSdk
        .restoreInspectedBuilderRequest();
  }

  void handleQrFailure(QrInputFailure failure) {
    qrInputError.value = switch (failure) {
      QrInputFailure.cancelled => '',
      QrInputFailure.permissionDenied =>
        'Camera access was denied. Import a QR image instead.',
      QrInputFailure.unreadable =>
        "We couldn't find a readable activation QR in that image.",
      QrInputFailure.multipleCodes =>
        'Use an image or camera view containing only one QR code.',
    };
  }

  Future<void> openActivationQr() async {
    final ActivationRequestReview? review = activationRequestReview.value;
    if (review == null || isCreatingActivationResponse.value) return;
    isCreatingActivationResponse.value = true;
    activationResponseError.value = '';
    try {
      activationResponse.value = await _walletSdk.approveBuilderRequest(
        review.requestId,
      );
      Get.toNamed(Routes.appMasterActivationQr);
    } on WalletSdkException catch (error) {
      activationResponseError.value = error.safeMessage;
    } catch (_) {
      activationResponseError.value =
          "We couldn't create the activation package. Try again.";
    } finally {
      isCreatingActivationResponse.value = false;
    }
  }

  void finishActivation() => Get.offAllNamed(Routes.appMaster);
}
