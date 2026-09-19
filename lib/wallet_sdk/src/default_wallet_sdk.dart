import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:the_builder_pros/wallet_sdk/src/activation/activation_token_generator.dart';
import 'package:the_builder_pros/wallet_sdk/src/activation/activation_response_service.dart';
import 'package:the_builder_pros/wallet_sdk/src/authority/distributor_authority_service.dart';
import 'package:the_builder_pros/wallet_sdk/src/configuration/configuration_policy.dart';
import 'package:the_builder_pros/wallet_sdk/src/configuration/provider_configuration.dart';
import 'package:the_builder_pros/wallet_sdk/src/configuration/configuration_handshake_service.dart';
import 'package:the_builder_pros/wallet_sdk/src/crypto/device_configuration_identity.dart';
import 'package:the_builder_pros/wallet_sdk/src/crypto/wallet_key_generator.dart';
import 'package:the_builder_pros/wallet_sdk/src/qr/activation_qr_codec.dart';
import 'package:the_builder_pros/wallet_sdk/src/protocol/stellar_activation_protocol.dart';
import 'package:the_builder_pros/wallet_sdk/src/storage/activation_store.dart';
import 'package:the_builder_pros/wallet_sdk/src/storage/activation_submission_store.dart';
import 'package:the_builder_pros/wallet_sdk/src/storage/activation_inspection_store.dart';
import 'package:the_builder_pros/wallet_sdk/src/storage/credential_store.dart';
import 'package:the_builder_pros/wallet_sdk/src/storage/configuration_store.dart';
import 'package:the_builder_pros/wallet_sdk/src/storage/configuration_handshake_store.dart';
import 'package:the_builder_pros/wallet_sdk/src/time/wallet_clock.dart';
import 'package:the_builder_pros/wallet_sdk/src/transport/horizon_health_client.dart';
import 'package:the_builder_pros/wallet_sdk/src/transport/distributor_status_client.dart';
import 'package:the_builder_pros/wallet_sdk/src/transport/activation_submission_client.dart';
import 'package:the_builder_pros/wallet_sdk/src/transport/activation_reconciliation_client.dart';
import 'package:the_builder_pros/wallet_sdk/wallet_sdk.dart';

final class DefaultWalletSdk implements WalletSdk {
  DefaultWalletSdk({
    FlutterSecureStorage? secureStorage,
    DateTime Function()? now,
    Random? random,
    WalletKeyGenerator? keyGenerator,
    ActivationQrCodec? qrCodec,
    ActivationStore? activationStore,
    CredentialStore? credentialStore,
    WalletClock? clock,
    ActivationTokenGenerator? tokenGenerator,
    ConfigurationPolicy configurationPolicy = const ConfigurationPolicy(),
    ConfigurationStore? configurationStore,
    HorizonHealthClient? horizonHealthClient,
    DeviceConfigurationIdentityService? deviceIdentityService,
    ActivationInspectionStore? activationInspectionStore,
    DistributorAuthorityService? distributorAuthorityService,
    DistributorStatusClient? distributorStatusClient,
    ActivationResponseService? activationResponseService,
    ActivationSubmissionStore? activationSubmissionStore,
    ActivationSubmissionClient? activationSubmissionClient,
    ActivationReconciliationClient? activationReconciliationClient,
    StellarActivationProtocol? stellarProtocol,
    ConfigurationHandshakeService? configurationHandshakeService,
    ConfigurationHandshakeStore? configurationHandshakeStore,
  }) : _activationStore = activationStore ?? PreferencesActivationStore(),
       _credentialStore =
           credentialStore ?? SecureCredentialStore(storage: secureStorage),
       _clock =
           clock ??
           (now == null ? const SystemWalletClock() : CallbackWalletClock(now)),
       _tokenGenerator =
           tokenGenerator ?? ActivationTokenGenerator(random: random),
       _keyGenerator = keyGenerator ?? WalletKeyGenerator(random: random),
       _qrCodec = qrCodec ?? ActivationQrCodec(),
       _deviceIdentityService =
           deviceIdentityService ??
           DeviceConfigurationIdentityService(
             credentialStore:
                 credentialStore ??
                 SecureCredentialStore(storage: secureStorage),
             random: random,
           ),
       _configurationPolicy = configurationPolicy,
       _configurationStore =
           configurationStore ??
           ProtectedConfigurationStore(secureStorage: secureStorage),
       _horizonHealthClient =
           horizonHealthClient ?? DirectHorizonHealthClient(),
       _activationInspectionStore =
           activationInspectionStore ??
           ProtectedActivationInspectionStore(secureStorage: secureStorage),
       _distributorAuthorityService =
           distributorAuthorityService ??
           DistributorAuthorityService(
             store: ProtectedDistributorAuthorityStore(
               secureStorage: secureStorage,
             ),
             verifier: HorizonDistributorAccountVerifier(),
           ),
       _distributorStatusClient =
           distributorStatusClient ?? DirectDistributorStatusClient(),
       _activationResponseService =
           activationResponseService ??
           ActivationResponseService(random: random),
       _activationSubmissionStore =
           activationSubmissionStore ?? PreferencesActivationSubmissionStore(),
       _activationSubmissionClient =
           activationSubmissionClient ?? DirectActivationSubmissionClient(),
       _activationReconciliationClient =
           activationReconciliationClient ??
           DirectActivationReconciliationClient(),
       _stellarProtocol = stellarProtocol ?? StellarActivationProtocol(),
       _configurationHandshakeService =
           configurationHandshakeService ??
           ConfigurationHandshakeService(random: random),
       _configurationHandshakeStore =
           configurationHandshakeStore ??
           ConfigurationHandshakeStore(secureStorage: secureStorage);

  static const String _credentialKeyPrefix = 'rewards.activation.secret.';
  static const Duration _requestLifetime = Duration(minutes: 15);

  final ActivationStore _activationStore;
  final CredentialStore _credentialStore;
  final WalletClock _clock;
  final ActivationTokenGenerator _tokenGenerator;
  final WalletKeyGenerator _keyGenerator;
  final ActivationQrCodec _qrCodec;
  final DeviceConfigurationIdentityService _deviceIdentityService;
  final ConfigurationPolicy _configurationPolicy;
  final ConfigurationStore _configurationStore;
  final HorizonHealthClient _horizonHealthClient;
  final ActivationInspectionStore _activationInspectionStore;
  final DistributorAuthorityService _distributorAuthorityService;
  final DistributorStatusClient _distributorStatusClient;
  final ActivationResponseService _activationResponseService;
  final ActivationSubmissionStore _activationSubmissionStore;
  final ActivationSubmissionClient _activationSubmissionClient;
  final ActivationReconciliationClient _activationReconciliationClient;
  final StellarActivationProtocol _stellarProtocol;
  final ConfigurationHandshakeService _configurationHandshakeService;
  final ConfigurationHandshakeStore _configurationHandshakeStore;

  @override
  Future<ActivationRequestView> startActivation(BuilderIdentity builder) async {
    final ActivationRequestView? existing = await restoreActivationRequest();
    if (existing != null) {
      return existing;
    }

    final String name = builder.displayName.trim();
    final String phone = builder.phone.trim();
    if (name.isEmpty || !phone.startsWith('+') || phone.length < 8) {
      throw const WalletSdkException(
        code: WalletSdkFailureCode.invalidBuilder,
        safeMessage: 'Check your Builder name and phone number.',
        canRetry: true,
      );
    }

    final DateTime createdAt = _clock.nowUtc();
    final DateTime expiresAt = createdAt.add(_requestLifetime);
    final String requestId = _tokenGenerator.createRequestId();
    final String credentialKey = '$_credentialKeyPrefix$requestId';

    try {
      final WalletKeyPair keyPair = await _keyGenerator.generate();
      final DeviceConfigurationIdentity deviceIdentity =
          await _deviceIdentityService.getOrCreate();
      await _credentialStore.write(
        key: credentialKey,
        value: keyPair.secretSeed,
      );

      final BuilderIdentity normalizedBuilder = BuilderIdentity(
        displayName: name,
        phone: phone,
      );
      final String qrValue = await _qrCodec.encodeRequest(
        requestId: requestId,
        challenge: _tokenGenerator.createToken(24),
        createdAt: createdAt,
        expiresAt: expiresAt,
        builder: normalizedBuilder,
        activationAddress: keyPair.accountId,
        deviceId: deviceIdentity.deviceId,
        devicePublicKey: deviceIdentity.publicKey,
      );
      await _activationStore.write(
        PendingActivationRecord(
          requestId: requestId,
          qrValue: qrValue,
          expiresAt: expiresAt,
          credentialKey: credentialKey,
          builderName: name,
          builderPhone: phone,
        ),
      );

      return ActivationRequestView(
        requestId: requestId,
        qrValue: qrValue,
        expiresAt: expiresAt,
        builder: normalizedBuilder,
      );
    } catch (_) {
      await _credentialStore.delete(credentialKey);
      await _activationStore.clear();
      throw const WalletSdkException(
        code: WalletSdkFailureCode.requestCreationFailed,
        safeMessage: "We couldn't prepare your activation request. Try again.",
        canRetry: true,
      );
    }
  }

  @override
  Future<ActivationRequestView?> restoreActivationRequest() async {
    try {
      if ((await getActivationStatus()).state == WalletActivationState.active) {
        return null;
      }
      final PendingActivationRecord? stored = await _activationStore.read();
      if (stored == null) {
        return null;
      }

      late final DecodedActivationRequest decoded;
      try {
        decoded = await _qrCodec.decodeAndValidate(
          stored.qrValue,
          now: _clock.nowUtc(),
        );
      } on FormatException {
        await _clearAttempt(stored.credentialKey);
        return null;
      }
      if (decoded.requestId != stored.requestId ||
          decoded.expiresAt != stored.expiresAt) {
        await _clearAttempt(stored.credentialKey);
        return null;
      }

      final bool hasProtectedSetup = await _credentialStore.contains(
        stored.credentialKey,
      );
      if (!hasProtectedSetup || !_clock.nowUtc().isBefore(stored.expiresAt)) {
        await _clearAttempt(stored.credentialKey);
        return null;
      }

      return ActivationRequestView(
        requestId: stored.requestId,
        qrValue: stored.qrValue,
        expiresAt: stored.expiresAt,
        builder: BuilderIdentity(
          displayName: stored.builderName,
          phone: stored.builderPhone,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> cancelActivation() async {
    try {
      final PendingActivationRecord? stored = await _activationStore.read();
      if (stored == null) {
        return;
      }
      await _clearAttempt(stored.credentialKey);
    } catch (_) {
      throw const WalletSdkException(
        code: WalletSdkFailureCode.cancellationFailed,
        safeMessage: "We couldn't cancel this activation. Try again.",
        canRetry: true,
      );
    }
  }

  @override
  Future<ActivationRequestReview> inspectBuilderRequest(String qrValue) async {
    try {
      final DecodedActivationRequest decoded = await _qrCodec.decodeAndValidate(
        qrValue,
        now: _clock.nowUtc(),
      );
      if (await _activationInspectionStore.isConsumed(decoded.requestId)) {
        throw const WalletSdkException(
          code: WalletSdkFailureCode.activationRequestAlreadyUsed,
          safeMessage: 'This activation request has already been used.',
          canRetry: false,
        );
      }
      await _activationInspectionStore.savePendingRequest(qrValue);
      return _toReview(decoded);
    } on WalletSdkException {
      rethrow;
    } on ExpiredActivationRequestException {
      throw const WalletSdkException(
        code: WalletSdkFailureCode.activationRequestExpired,
        safeMessage:
            'This activation request has expired. Ask the Builder for a new one.',
        canRetry: false,
      );
    } on FormatException {
      throw const WalletSdkException(
        code: WalletSdkFailureCode.invalidActivationRequest,
        safeMessage: "We couldn't verify this activation request.",
        canRetry: false,
      );
    } catch (_) {
      throw const WalletSdkException(
        code: WalletSdkFailureCode.unavailable,
        safeMessage: "We couldn't inspect this activation request. Try again.",
        canRetry: true,
      );
    }
  }

  @override
  Future<ActivationRequestReview?> restoreInspectedBuilderRequest() async {
    try {
      final String? qrValue = await _activationInspectionStore
          .readPendingRequest();
      if (qrValue == null) {
        return null;
      }
      return await inspectBuilderRequest(qrValue);
    } catch (_) {
      try {
        await _activationInspectionStore.clearPendingRequest();
      } catch (_) {
        // Restoration remains fail-closed even if stale-state cleanup fails.
      }
      return null;
    }
  }

  @override
  Future<ActivationResponseView> approveBuilderRequest(String requestId) async {
    try {
      final String? qrValue = await _activationInspectionStore
          .readPendingRequest();
      final ProviderConfiguration? configuration = await _configurationStore
          .readActive();
      final String? distributorSecret = await _distributorAuthorityService
          .readSecret();
      if (configuration == null) {
        throw const WalletSdkException(
          code: WalletSdkFailureCode.providerConfigurationRequired,
          safeMessage: 'Verify the activation service settings first.',
          canRetry: false,
        );
      }
      if (qrValue == null || distributorSecret == null) {
        throw const WalletSdkException(
          code: WalletSdkFailureCode.activationApprovalFailed,
          safeMessage: 'Complete App Master setup and scan the request again.',
          canRetry: false,
        );
      }
      final DecodedActivationRequest request = await _qrCodec.decodeAndValidate(
        qrValue,
        now: _clock.nowUtc(),
      );
      if (request.requestId != requestId ||
          await _activationInspectionStore.isConsumed(requestId)) {
        throw const WalletSdkException(
          code: WalletSdkFailureCode.invalidActivationRequest,
          safeMessage: "We couldn't verify this activation request.",
          canRetry: false,
        );
      }
      final String distributorAccount = await _distributorAuthorityService
          .deriveAccountId(distributorSecret);
      final DistributorLedgerStatus ledger = await _distributorStatusClient
          .load(configuration: configuration, accountId: distributorAccount);
      return _activationResponseService.create(
        request: request,
        configuration: configuration,
        ledger: ledger,
        distributorAccount: distributorAccount,
        distributorSecret: distributorSecret,
        now: _clock.nowUtc(),
        responseId: _tokenGenerator.createRequestId().replaceFirst(
          'ACT-',
          'RES-',
        ),
      );
    } on WalletSdkException {
      rethrow;
    } on ExpiredActivationRequestException {
      throw const WalletSdkException(
        code: WalletSdkFailureCode.activationRequestExpired,
        safeMessage: 'This activation request has expired.',
        canRetry: false,
      );
    } catch (_) {
      throw const WalletSdkException(
        code: WalletSdkFailureCode.activationApprovalFailed,
        safeMessage: "We couldn't create the activation package. Try again.",
        canRetry: true,
      );
    }
  }

  @override
  Future<ActivationReview> inspectActivationResponse(String qrValue) async {
    try {
      final PendingActivationRecord? pending = await _activationStore.read();
      if (pending == null) {
        throw const WalletSdkException(
          code: WalletSdkFailureCode.invalidActivationResponse,
          safeMessage: 'Start activation on this device first.',
          canRetry: false,
        );
      }
      final DecodedActivationRequest request = await _qrCodec.decodeAndValidate(
        pending.qrValue,
        now: _clock.nowUtc(),
      );
      final ActivationReview review = await _activationResponseService.inspect(
        encoded: qrValue,
        request: request,
        deviceKeyPair: await _deviceIdentityService.readPrivateKeyPair(),
        now: _clock.nowUtc(),
      );
      if (await _activationInspectionStore.isConsumed(review.responseId)) {
        throw const WalletSdkException(
          code: WalletSdkFailureCode.invalidActivationResponse,
          safeMessage: 'This activation package has already been reviewed.',
          canRetry: false,
        );
      }
      await _activationInspectionStore.savePendingResponse(qrValue);
      await _activationInspectionStore.markConsumed(review.responseId);
      return review;
    } on WalletSdkException {
      rethrow;
    } on ExpiredActivationResponseException {
      throw const WalletSdkException(
        code: WalletSdkFailureCode.activationResponseExpired,
        safeMessage: 'This activation has expired. Request a new one.',
        canRetry: false,
      );
    } on SecretBoxAuthenticationError {
      throw const WalletSdkException(
        code: WalletSdkFailureCode.invalidActivationResponse,
        safeMessage: "This activation wasn't prepared for this device.",
        canRetry: false,
      );
    } on FormatException {
      throw const WalletSdkException(
        code: WalletSdkFailureCode.invalidActivationResponse,
        safeMessage: "We couldn't verify this activation package.",
        canRetry: false,
      );
    } catch (_) {
      throw const WalletSdkException(
        code: WalletSdkFailureCode.unavailable,
        safeMessage: "We couldn't inspect this activation. Try again.",
        canRetry: true,
      );
    }
  }

  @override
  Future<ActivationOutcome> approveActivation(String responseId) async {
    final ActivationSubmissionRecord? existing =
        await _activationSubmissionStore.read();
    if (existing != null && existing.responseId == responseId) {
      return _toActivationOutcome(existing);
    }
    try {
      final PendingActivationRecord? pending = await _activationStore.read();
      final String? response = await _activationInspectionStore
          .readPendingResponse();
      if (pending == null ||
          response == null ||
          !await _activationInspectionStore.isConsumed(responseId)) {
        throw const WalletSdkException(
          code: WalletSdkFailureCode.invalidActivationResponse,
          safeMessage: 'Review this activation package before approving it.',
          canRetry: false,
        );
      }
      final DecodedActivationRequest request = await _qrCodec.decodeAndValidate(
        pending.qrValue,
        now: _clock.nowUtc(),
      );
      final InspectedActivationResponse inspected =
          await _activationResponseService.inspectDetails(
            encoded: response,
            request: request,
            deviceKeyPair: await _deviceIdentityService.readPrivateKeyPair(),
            now: _clock.nowUtc(),
          );
      if (inspected.review.responseId != responseId) {
        throw const WalletSdkException(
          code: WalletSdkFailureCode.invalidActivationResponse,
          safeMessage: 'The reviewed activation package does not match.',
          canRetry: false,
        );
      }
      final String? builderSecret = await _credentialStore.read(
        pending.credentialKey,
      );
      if (builderSecret == null) {
        throw const WalletSdkException(
          code: WalletSdkFailureCode.activationSubmissionFailed,
          safeMessage: 'The protected activation key is unavailable.',
          canRetry: false,
        );
      }
      final String passphrase =
          inspected.configuration.environment == ProviderEnvironment.test
          ? StellarActivationProtocol.testNetworkPassphrase
          : StellarActivationProtocol.publicNetworkPassphrase;
      final List<int> hash = await _stellarProtocol.transactionHash(
        inspected.envelope,
        passphrase,
      );
      final String transactionHash = hash
          .map((int byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join();
      await _activationSubmissionStore.write(
        ActivationSubmissionRecord(
          responseId: responseId,
          transactionHash: transactionHash,
          status: ActivationSubmissionStatus.submitting,
        ),
      );
      final StellarActivationEnvelope signed = await _stellarProtocol.sign(
        inspected.envelope,
        secretSeed: builderSecret,
        networkPassphrase: passphrase,
      );
      final ActivationSubmissionResult result =
          await _activationSubmissionClient.submit(
            configuration: inspected.configuration,
            envelopeXdr: _stellarProtocol.encodeEnvelopeBase64(signed),
          );
      final ActivationSubmissionStatus status = switch (result) {
        ActivationSubmissionResult.accepted =>
          ActivationSubmissionStatus.submitted,
        ActivationSubmissionResult.rejected =>
          ActivationSubmissionStatus.rejected,
        ActivationSubmissionResult.uncertain =>
          ActivationSubmissionStatus.uncertain,
      };
      final ActivationSubmissionRecord record = ActivationSubmissionRecord(
        responseId: responseId,
        transactionHash: transactionHash,
        status: status,
      );
      await _activationSubmissionStore.write(record);
      return _toActivationOutcome(record);
    } on WalletSdkException {
      rethrow;
    } on FormatException {
      throw const WalletSdkException(
        code: WalletSdkFailureCode.invalidActivationResponse,
        safeMessage: "We couldn't verify this activation package.",
        canRetry: false,
      );
    } catch (_) {
      throw const WalletSdkException(
        code: WalletSdkFailureCode.activationSubmissionFailed,
        safeMessage:
            "We couldn't submit this activation. Check its status later.",
        canRetry: false,
      );
    }
  }

  @override
  Future<WalletActivationStatus> getActivationStatus() async {
    try {
      final ActivationSubmissionRecord? record =
          await _activationSubmissionStore.read();
      return record == null
          ? const WalletActivationStatus.notActivated()
          : _toWalletActivationStatus(record.status);
    } catch (_) {
      return const WalletActivationStatus.notActivated();
    }
  }

  @override
  Future<WalletActivationStatus> reconcileActivation() async {
    final ActivationSubmissionRecord? record = await _activationSubmissionStore
        .read();
    if (record == null) return const WalletActivationStatus.notActivated();
    if (record.status == ActivationSubmissionStatus.verified ||
        record.status == ActivationSubmissionStatus.rejected) {
      return _toWalletActivationStatus(record.status);
    }
    try {
      final PendingActivationRecord? pending = await _activationStore.read();
      final String? response = await _activationInspectionStore
          .readPendingResponse();
      if (pending == null || response == null) {
        return _toWalletActivationStatus(ActivationSubmissionStatus.uncertain);
      }
      final DecodedActivationRequest request = await _qrCodec.decodeAndValidate(
        pending.qrValue,
        now: pending.expiresAt.subtract(const Duration(microseconds: 1)),
      );
      final InspectedActivationResponse inspected =
          await _activationResponseService.inspectDetails(
            encoded: response,
            request: request,
            deviceKeyPair: await _deviceIdentityService.readPrivateKeyPair(),
            now: _clock.nowUtc(),
            allowExpired: true,
          );
      final StellarChangeTrustOperation trust =
          inspected.envelope.operations[1] as StellarChangeTrustOperation;
      ActivationReconciliationResult result =
          ActivationReconciliationResult.pending;
      for (int attempt = 0; attempt < 3; attempt++) {
        result = await _activationReconciliationClient.reconcile(
          configuration: inspected.configuration,
          transactionHash: record.transactionHash,
          builderAccount: request.activationAddress,
          assetCode: trust.asset.code!,
          assetIssuer: trust.asset.issuer!,
          minimumRewards: 1,
        );
        if (result != ActivationReconciliationResult.pending) break;
      }
      if (result == ActivationReconciliationResult.verified) {
        await _configurationStore.savePending(inspected.configuration);
        try {
          await _horizonHealthClient.check(inspected.configuration);
          await _configurationStore.promotePending(_clock.nowUtc());
        } catch (_) {
          await _discardPendingSafely();
          return _toWalletActivationStatus(
            ActivationSubmissionStatus.uncertain,
          );
        }
        await _activationSubmissionStore.write(
          ActivationSubmissionRecord(
            responseId: record.responseId,
            transactionHash: record.transactionHash,
            status: ActivationSubmissionStatus.verified,
          ),
        );
        return _toWalletActivationStatus(ActivationSubmissionStatus.verified);
      }
      if (result == ActivationReconciliationResult.failed) {
        await _activationSubmissionStore.write(
          ActivationSubmissionRecord(
            responseId: record.responseId,
            transactionHash: record.transactionHash,
            status: ActivationSubmissionStatus.rejected,
          ),
        );
        return _toWalletActivationStatus(ActivationSubmissionStatus.rejected);
      }
      await _activationSubmissionStore.write(
        ActivationSubmissionRecord(
          responseId: record.responseId,
          transactionHash: record.transactionHash,
          status: ActivationSubmissionStatus.uncertain,
        ),
      );
      return _toWalletActivationStatus(ActivationSubmissionStatus.uncertain);
    } catch (_) {
      return _toWalletActivationStatus(ActivationSubmissionStatus.uncertain);
    }
  }

  @override
  Future<ConfigurationRequestView> createConfigurationRequest() async {
    try {
      final ProviderConfiguration? active = await _configurationStore
          .readActive();
      if (active == null) {
        throw const WalletSdkException(
          code: WalletSdkFailureCode.providerConfigurationRequired,
          safeMessage: 'Activate Rewards before updating service settings.',
          canRetry: false,
        );
      }
      final DeviceConfigurationIdentity device = await _deviceIdentityService
          .getOrCreate();
      final DateTime now = _clock.nowUtc();
      final String requestId = _tokenGenerator.createRequestId().replaceFirst(
        'ACT-',
        'CFG-',
      );
      final String qrValue = await _configurationHandshakeService.createRequest(
        requestId: requestId,
        deviceId: device.deviceId,
        devicePublicKey: device.publicKey,
        currentVersion: active.version,
        environment: active.environment,
        challenge: _tokenGenerator.createToken(24),
        now: now,
      );
      await _configurationHandshakeStore.saveRequest(qrValue);
      return ConfigurationRequestView(
        requestId: requestId,
        qrValue: qrValue,
        expiresAt: now.add(ConfigurationHandshakeService.lifetime),
      );
    } on WalletSdkException {
      rethrow;
    } catch (_) {
      throw const WalletSdkException(
        code: WalletSdkFailureCode.invalidConfigurationRequest,
        safeMessage: "We couldn't create the settings request.",
        canRetry: true,
      );
    }
  }

  @override
  Future<ConfigurationRequestReview> inspectConfigurationRequest(
    String qrValue,
  ) async {
    try {
      final DecodedConfigurationRequest request =
          await _configurationHandshakeService.inspectRequest(
            qrValue,
            _clock.nowUtc(),
          );
      await _configurationHandshakeStore.saveRequest(qrValue);
      return ConfigurationRequestReview(
        requestId: request.requestId,
        currentVersion: request.currentVersion,
        environment: request.environment,
        expiresAt: request.expiresAt,
      );
    } catch (_) {
      throw const WalletSdkException(
        code: WalletSdkFailureCode.invalidConfigurationRequest,
        safeMessage: "We couldn't verify this settings request.",
        canRetry: false,
      );
    }
  }

  @override
  Future<ConfigurationUpdateView> createConfigurationUpdate(
    String requestId,
  ) async {
    try {
      final String? rawRequest = await _configurationHandshakeStore
          .readRequest();
      final ProviderConfiguration? configuration = await _configurationStore
          .readActive();
      final String? secret = await _distributorAuthorityService.readSecret();
      if (rawRequest == null || configuration == null || secret == null) {
        throw const FormatException(
          'Configuration update setup is incomplete.',
        );
      }
      final DecodedConfigurationRequest request =
          await _configurationHandshakeService.inspectRequest(
            rawRequest,
            _clock.nowUtc(),
          );
      if (request.requestId != requestId) {
        throw const FormatException('Configuration request mismatch.');
      }
      final DateTime now = _clock.nowUtc();
      final String updateId = _tokenGenerator.createRequestId().replaceFirst(
        'ACT-',
        'UPD-',
      );
      final String qrValue = await _configurationHandshakeService.createUpdate(
        updateId: updateId,
        request: request,
        configuration: configuration,
        signingSecret: secret,
        signerAccount: await _distributorAuthorityService.deriveAccountId(
          secret,
        ),
        now: now,
      );
      return ConfigurationUpdateView(
        updateId: updateId,
        requestId: requestId,
        qrValue: qrValue,
        expiresAt:
            now
                .add(ConfigurationHandshakeService.lifetime)
                .isBefore(request.expiresAt)
            ? now.add(ConfigurationHandshakeService.lifetime)
            : request.expiresAt,
      );
    } catch (_) {
      throw const WalletSdkException(
        code: WalletSdkFailureCode.invalidConfigurationUpdate,
        safeMessage: "We couldn't create the settings update.",
        canRetry: false,
      );
    }
  }

  @override
  Future<ConfigurationReview> inspectConfigurationUpdate(String qrValue) async {
    try {
      final String? rawRequest = await _configurationHandshakeStore
          .readRequest();
      final ProviderConfiguration? active = await _configurationStore
          .readActive();
      if (rawRequest == null || active == null) {
        throw const FormatException('Configuration request is unavailable.');
      }
      final DecodedConfigurationRequest request =
          await _configurationHandshakeService.inspectRequest(
            rawRequest,
            _clock.nowUtc(),
          );
      final InspectedConfigurationUpdate inspected =
          await _configurationHandshakeService.inspectUpdate(
            encoded: qrValue,
            request: request,
            deviceKeyPair: await _deviceIdentityService.readPrivateKeyPair(),
            installedVersion: active.version,
            now: _clock.nowUtc(),
          );
      if (await _configurationHandshakeStore.isConsumed(
        inspected.review.updateId,
      )) {
        throw const WalletSdkException(
          code: WalletSdkFailureCode.configurationUpdateAlreadyUsed,
          safeMessage: 'This settings update has already been used.',
          canRetry: false,
        );
      }
      await _configurationStore.savePending(inspected.configuration);
      await _configurationHandshakeStore.saveUpdate(
        qrValue,
        inspected.review.updateId,
      );
      return inspected.review;
    } on ExpiredConfigurationUpdateException {
      throw const WalletSdkException(
        code: WalletSdkFailureCode.configurationUpdateExpired,
        safeMessage: 'This settings update has expired.',
        canRetry: false,
      );
    } on WalletSdkException {
      rethrow;
    } catch (_) {
      await _discardPendingSafely();
      throw const WalletSdkException(
        code: WalletSdkFailureCode.invalidConfigurationUpdate,
        safeMessage: "We couldn't verify this settings update.",
        canRetry: false,
      );
    }
  }

  @override
  Future<ConfigurationOutcome> applyConfigurationUpdate(String updateId) async {
    try {
      if (await _configurationHandshakeStore.isConsumed(updateId)) {
        throw const WalletSdkException(
          code: WalletSdkFailureCode.configurationUpdateAlreadyUsed,
          safeMessage: 'This settings update has already been used.',
          canRetry: false,
        );
      }
      final String? reviewedId = await _configurationHandshakeStore
          .readReviewedUpdateId();
      final ProviderConfiguration? candidate = await _configurationStore
          .readPending();
      if (reviewedId != updateId || candidate == null) {
        throw const WalletSdkException(
          code: WalletSdkFailureCode.invalidConfigurationUpdate,
          safeMessage: 'Review the matching settings update first.',
          canRetry: false,
        );
      }
      await _horizonHealthClient.check(candidate);
      await _configurationStore.promotePending(_clock.nowUtc());
      await _configurationHandshakeStore.markConsumed(updateId);
      return ConfigurationOutcome(
        status: await _configurationStore.readStatus(),
      );
    } on WalletSdkException {
      await _discardPendingSafely();
      rethrow;
    } catch (_) {
      await _discardPendingSafely();
      throw const WalletSdkException(
        code: WalletSdkFailureCode.invalidConfigurationUpdate,
        safeMessage: "We couldn't apply this settings update.",
        canRetry: true,
      );
    }
  }

  @override
  Future<DistributorAuthorityStatus> importDistributorSecret(
    String secret,
  ) async {
    final String candidate = secret.trim();
    final ProviderConfiguration? configuration = await _configurationStore
        .readActive();
    if (configuration == null) {
      throw const WalletSdkException(
        code: WalletSdkFailureCode.providerConfigurationRequired,
        safeMessage: 'Verify the activation service settings first.',
        canRetry: false,
      );
    }
    try {
      await _distributorAuthorityService.verifyAndStore(
        secret: candidate,
        configuration: configuration,
      );
      final String accountId = await _distributorAuthorityService
          .deriveAccountId(candidate);
      return DistributorAuthorityStatus(
        state: DistributorAuthorityState.ready,
        maskedAccountId: _maskAccountId(accountId),
        environment: configuration.environment,
        verifiedAt: _clock.nowUtc(),
      );
    } on FormatException {
      throw const WalletSdkException(
        code: WalletSdkFailureCode.invalidDistributorSecret,
        safeMessage: 'The distributor secret is not valid.',
        canRetry: true,
      );
    } on WalletSdkException {
      rethrow;
    } catch (_) {
      throw const WalletSdkException(
        code: WalletSdkFailureCode.distributorAuthoritySaveFailed,
        safeMessage: "We couldn't protect the distributor account. Try again.",
        canRetry: true,
      );
    }
  }

  @override
  Future<DistributorAuthorityStatus> getDistributorAuthorityStatus() async {
    try {
      final String? accountId = await _distributorAuthorityService
          .readAccountId();
      if (accountId == null) {
        return const DistributorAuthorityStatus.notConfigured();
      }
      final ProviderConfiguration? configuration = await _configurationStore
          .readActive();
      return DistributorAuthorityStatus(
        state: DistributorAuthorityState.ready,
        maskedAccountId: _maskAccountId(accountId),
        environment: configuration?.environment,
      );
    } catch (_) {
      return const DistributorAuthorityStatus.notConfigured();
    }
  }

  @override
  Future<void> removeDistributorAuthority() async {
    try {
      await _distributorAuthorityService.clear();
    } catch (_) {
      throw const WalletSdkException(
        code: WalletSdkFailureCode.distributorAuthoritySaveFailed,
        safeMessage: "We couldn't remove the distributor account. Try again.",
        canRetry: true,
      );
    }
  }

  @override
  Future<AppMasterOverview> getAppMasterOverview() async {
    final ProviderConfiguration? configuration = await _configurationStore
        .readActive();
    final String? accountId = await _distributorAuthorityService
        .readAccountId();
    if (configuration == null || accountId == null) {
      throw const WalletSdkException(
        code: WalletSdkFailureCode.providerConfigurationRequired,
        safeMessage: 'Complete the App Master setup in Advanced first.',
        canRetry: false,
      );
    }
    final DistributorLedgerStatus status = await _distributorStatusClient.load(
      configuration: configuration,
      accountId: accountId,
    );
    const double baseReserve = 0.5;
    const double activationFundingPolicy = 2.1;
    final double retainedReserve =
        (2 + status.subentryCount) * baseReserve +
        status.nativeSellingLiabilities +
        (status.feeP95Stroops * 3 / 10000000) +
        0.5;
    final double spendable = (status.nativeBalance - retainedReserve).clamp(
      0,
      double.infinity,
    );
    final int capacity = (spendable / activationFundingPolicy).floor();
    final String rewardsAvailable =
        status.nonNativeSpendableBalances.length == 1
        ? _formatRewards(status.nonNativeSpendableBalances.single)
        : status.nonNativeSpendableBalances.isEmpty
        ? 'Not available'
        : 'Needs review';
    return AppMasterOverview(
      activationCapacity: capacity,
      rewardsAvailable: rewardsAvailable,
      serviceStatus: capacity > 0 ? 'Ready for activations' : 'Needs funding',
      updatedAt: _clock.nowUtc(),
    );
  }

  @override
  Future<ProviderConfigurationOutcome> saveAppMasterProviderConfiguration(
    ProviderConfigurationInput input,
  ) async {
    final configuration = _configurationPolicy.validate(input);
    try {
      await _configurationStore.savePending(configuration);
    } catch (_) {
      throw const WalletSdkException(
        code: WalletSdkFailureCode.providerConfigurationSaveFailed,
        safeMessage: "We couldn't protect these settings. Try again.",
        canRetry: true,
      );
    }

    try {
      await _horizonHealthClient.check(configuration);
    } on WalletSdkException {
      await _discardPendingSafely();
      rethrow;
    } catch (_) {
      await _discardPendingSafely();
      throw const WalletSdkException(
        code: WalletSdkFailureCode.providerServiceUnavailable,
        safeMessage: 'The activation service is unavailable. Try again.',
        canRetry: true,
      );
    }

    try {
      await _configurationStore.promotePending(_clock.nowUtc());
      return ProviderConfigurationOutcome(
        status: await _configurationStore.readStatus(),
      );
    } catch (_) {
      throw const WalletSdkException(
        code: WalletSdkFailureCode.providerConfigurationSaveFailed,
        safeMessage: "We couldn't protect these settings. Try again.",
        canRetry: true,
      );
    }
  }

  @override
  Future<ProviderConfigurationStatus> getProviderConfigurationStatus() async {
    try {
      return await _configurationStore.readStatus();
    } catch (_) {
      return const ProviderConfigurationStatus.notConfigured();
    }
  }

  Future<void> _discardPendingSafely() async {
    try {
      await _configurationStore.discardPending();
    } catch (_) {
      // The original safe health-check error remains authoritative.
    }
  }

  Future<void> _clearAttempt(String credentialKey) async {
    await _credentialStore.delete(credentialKey);
    await _activationStore.clear();
  }

  ActivationRequestReview _toReview(DecodedActivationRequest decoded) =>
      ActivationRequestReview(
        requestId: decoded.requestId,
        builder: decoded.builder,
        expiresAt: decoded.expiresAt,
        setupSteps: const <String>[
          'Set up Rewards',
          'Enable Rewards access',
          'Add starting Rewards',
        ],
      );

  ActivationOutcome _toActivationOutcome(ActivationSubmissionRecord record) {
    final ActivationOutcomeState state = switch (record.status) {
      ActivationSubmissionStatus.submitted => ActivationOutcomeState.submitted,
      ActivationSubmissionStatus.rejected => ActivationOutcomeState.rejected,
      ActivationSubmissionStatus.verified => ActivationOutcomeState.submitted,
      ActivationSubmissionStatus.submitting ||
      ActivationSubmissionStatus.uncertain => ActivationOutcomeState.uncertain,
    };
    final String message = switch (state) {
      ActivationOutcomeState.submitted =>
        'Activation submitted. Verifying Rewards setup…',
      ActivationOutcomeState.rejected =>
        'Activation was not accepted. Request a new activation.',
      ActivationOutcomeState.uncertain =>
        'Activation status is being checked. Do not submit it again.',
    };
    return ActivationOutcome(
      responseId: record.responseId,
      state: state,
      message: message,
    );
  }

  WalletActivationStatus _toWalletActivationStatus(
    ActivationSubmissionStatus status,
  ) => switch (status) {
    ActivationSubmissionStatus.verified => const WalletActivationStatus(
      state: WalletActivationState.active,
      message: 'Rewards is active.',
    ),
    ActivationSubmissionStatus.rejected => const WalletActivationStatus(
      state: WalletActivationState.failed,
      message: 'Activation was not accepted. Request a new activation.',
    ),
    ActivationSubmissionStatus.uncertain => const WalletActivationStatus(
      state: WalletActivationState.uncertain,
      message: 'Activation status is still being checked.',
    ),
    ActivationSubmissionStatus.submitting ||
    ActivationSubmissionStatus.submitted => const WalletActivationStatus(
      state: WalletActivationState.pending,
      message: 'Activation is being verified.',
    ),
  };

  String _maskAccountId(String accountId) =>
      '${accountId.substring(0, 6)}…${accountId.substring(accountId.length - 6)}';

  String _formatRewards(double value) {
    final String fixed = value.toStringAsFixed(7);
    return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
  }
}
