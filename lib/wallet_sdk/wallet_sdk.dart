library;

import 'package:the_builder_pros/wallet_sdk/src/default_wallet_sdk.dart';

WalletSdk createWalletSdk() => DefaultWalletSdk();

final class BuilderIdentity {
  const BuilderIdentity({required this.displayName, required this.phone});

  final String displayName;
  final String phone;
}

final class ActivationRequestView {
  const ActivationRequestView({
    required this.requestId,
    required this.qrValue,
    required this.expiresAt,
    required this.builder,
  });

  final String requestId;
  final String qrValue;
  final DateTime expiresAt;
  final BuilderIdentity builder;
}

final class ActivationRequestReview {
  const ActivationRequestReview({
    required this.requestId,
    required this.builder,
    required this.expiresAt,
    required this.setupSteps,
  });

  final String requestId;
  final BuilderIdentity builder;
  final DateTime expiresAt;
  final List<String> setupSteps;
}

final class ActivationResponseView {
  const ActivationResponseView({
    required this.responseId,
    required this.requestId,
    required this.qrValue,
    required this.expiresAt,
  });

  final String responseId;
  final String requestId;
  final String qrValue;
  final DateTime expiresAt;
}

final class ActivationReview {
  const ActivationReview({
    required this.responseId,
    required this.requestId,
    required this.expiresAt,
    required this.preparedBy,
    required this.setupSteps,
  });

  final String responseId;
  final String requestId;
  final DateTime expiresAt;
  final String preparedBy;
  final List<String> setupSteps;
}

enum ActivationOutcomeState { submitted, rejected, uncertain }

final class ActivationOutcome {
  const ActivationOutcome({
    required this.responseId,
    required this.state,
    required this.message,
  });

  final String responseId;
  final ActivationOutcomeState state;
  final String message;
}

enum WalletActivationState { notActivated, pending, active, failed, uncertain }

final class WalletActivationStatus {
  const WalletActivationStatus({required this.state, required this.message});

  const WalletActivationStatus.notActivated()
    : state = WalletActivationState.notActivated,
      message = 'Rewards is not activated.';

  final WalletActivationState state;
  final String message;
}

enum ProviderEnvironment { test, production }

enum ProviderConfigurationState { notConfigured, pendingVerification, ready }

enum DistributorAuthorityState { notConfigured, ready }

final class DistributorAuthorityStatus {
  const DistributorAuthorityStatus({
    required this.state,
    this.maskedAccountId,
    this.environment,
    this.verifiedAt,
  });

  const DistributorAuthorityStatus.notConfigured()
    : state = DistributorAuthorityState.notConfigured,
      maskedAccountId = null,
      environment = null,
      verifiedAt = null;

  final DistributorAuthorityState state;
  final String? maskedAccountId;
  final ProviderEnvironment? environment;
  final DateTime? verifiedAt;
}

final class AppMasterOverview {
  const AppMasterOverview({
    required this.activationCapacity,
    required this.rewardsAvailable,
    required this.serviceStatus,
    required this.updatedAt,
  });

  final int activationCapacity;
  final String rewardsAvailable;
  final String serviceStatus;
  final DateTime updatedAt;
}

final class ProviderConfigurationInput {
  const ProviderConfigurationInput({
    required this.endpoint,
    required this.apiKey,
    required this.environment,
    required this.version,
  });

  final String endpoint;
  final String apiKey;
  final ProviderEnvironment environment;
  final int version;
}

final class ProviderConfigurationOutcome {
  const ProviderConfigurationOutcome({required this.status});

  final ProviderConfigurationStatus status;
}

final class ConfigurationRequestView {
  const ConfigurationRequestView({
    required this.requestId,
    required this.qrValue,
    required this.expiresAt,
  });

  final String requestId;
  final String qrValue;
  final DateTime expiresAt;
}

final class ConfigurationRequestReview {
  const ConfigurationRequestReview({
    required this.requestId,
    required this.currentVersion,
    required this.environment,
    required this.expiresAt,
  });

  final String requestId;
  final int currentVersion;
  final ProviderEnvironment environment;
  final DateTime expiresAt;
}

final class ConfigurationUpdateView {
  const ConfigurationUpdateView({
    required this.updateId,
    required this.requestId,
    required this.qrValue,
    required this.expiresAt,
  });

  final String updateId;
  final String requestId;
  final String qrValue;
  final DateTime expiresAt;
}

final class ConfigurationReview {
  const ConfigurationReview({
    required this.updateId,
    required this.version,
    required this.environment,
    required this.endpointHost,
    required this.expiresAt,
  });

  final String updateId;
  final int version;
  final ProviderEnvironment environment;
  final String endpointHost;
  final DateTime expiresAt;
}

final class ConfigurationOutcome {
  const ConfigurationOutcome({required this.status});

  final ProviderConfigurationStatus status;
}

final class ProviderConfigurationStatus {
  const ProviderConfigurationStatus({
    required this.state,
    this.environment,
    this.version,
    this.endpointHost,
    this.lastCheckedAt,
  });

  const ProviderConfigurationStatus.notConfigured()
    : state = ProviderConfigurationState.notConfigured,
      environment = null,
      version = null,
      endpointHost = null,
      lastCheckedAt = null;

  final ProviderConfigurationState state;
  final ProviderEnvironment? environment;
  final int? version;
  final String? endpointHost;
  final DateTime? lastCheckedAt;
}

enum WalletSdkFailureCode {
  invalidBuilder,
  secureSetupFailed,
  requestCreationFailed,
  cancellationFailed,
  invalidProviderConfiguration,
  providerConfigurationSaveFailed,
  providerUnauthorized,
  providerRateLimited,
  providerServiceUnavailable,
  providerNetworkMismatch,
  providerInvalidResponse,
  providerTimeout,
  unavailable,
  invalidActivationRequest,
  activationRequestExpired,
  activationRequestAlreadyUsed,
  invalidDistributorSecret,
  distributorAccountUnavailable,
  distributorAuthoritySaveFailed,
  providerConfigurationRequired,
  activationApprovalFailed,
  activationPolicyUnavailable,
  invalidActivationResponse,
  activationResponseExpired,
  activationSubmissionFailed,
  invalidConfigurationRequest,
  invalidConfigurationUpdate,
  configurationUpdateExpired,
  configurationUpdateAlreadyUsed,
}

final class WalletSdkException implements Exception {
  const WalletSdkException({
    required this.code,
    required this.safeMessage,
    required this.canRetry,
  });

  final WalletSdkFailureCode code;
  final String safeMessage;
  final bool canRetry;
}

abstract interface class WalletSdk {
  Future<ActivationRequestView> startActivation(BuilderIdentity builder);

  Future<ActivationRequestView?> restoreActivationRequest();

  Future<void> cancelActivation();

  Future<ActivationRequestReview> inspectBuilderRequest(String qrValue);

  Future<ActivationRequestReview?> restoreInspectedBuilderRequest();

  Future<ActivationResponseView> approveBuilderRequest(String requestId);

  Future<ActivationReview> inspectActivationResponse(String qrValue);

  Future<ActivationOutcome> approveActivation(String responseId);

  Future<WalletActivationStatus> reconcileActivation();

  Future<WalletActivationStatus> getActivationStatus();

  Future<ConfigurationRequestView> createConfigurationRequest();

  Future<ConfigurationRequestReview> inspectConfigurationRequest(
    String qrValue,
  );

  Future<ConfigurationUpdateView> createConfigurationUpdate(String requestId);

  Future<ConfigurationReview> inspectConfigurationUpdate(String qrValue);

  Future<ConfigurationOutcome> applyConfigurationUpdate(String updateId);

  Future<DistributorAuthorityStatus> importDistributorSecret(String secret);

  Future<DistributorAuthorityStatus> getDistributorAuthorityStatus();

  Future<void> removeDistributorAuthority();

  Future<AppMasterOverview> getAppMasterOverview();

  Future<ProviderConfigurationOutcome> saveAppMasterProviderConfiguration(
    ProviderConfigurationInput input,
  );

  Future<ProviderConfigurationStatus> getProviderConfigurationStatus();
}
