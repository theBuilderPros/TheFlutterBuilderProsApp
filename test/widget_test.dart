import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:the_builder_pros/main_app.dart';
import 'package:the_builder_pros/app/features/app_master/controller/app_master_controller.dart';
import 'package:the_builder_pros/app/features/app_master/service/qr_input_adapter.dart';
import 'package:the_builder_pros/wallet_sdk/wallet_sdk.dart';

void main() {
  late _FakeWalletSdk fakeWalletSdk;
  late _FakeQrImagePicker fakeQrImagePicker;
  late _FakeQrImageDecoder fakeQrImageDecoder;

  setUp(() {
    Get.reset();
    fakeWalletSdk = _FakeWalletSdk();
    fakeQrImagePicker = _FakeQrImagePicker();
    fakeQrImageDecoder = _FakeQrImageDecoder();
    Get.put<WalletSdk>(fakeWalletSdk);
    Get.put<QrInputAdapter>(
      QrInputAdapter(
        imagePicker: fakeQrImagePicker,
        imageDecoder: fakeQrImageDecoder,
      ),
    );
  });

  tearDown(Get.reset);

  testWidgets('opens the User Wallet activation entry', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Rewards'), findsOneWidget);
    expect(find.text('Builder details'), findsOneWidget);
    expect(find.text('Rewards is not activated'), findsOneWidget);
    expect(find.byTooltip('Open App Master'), findsOneWidget);
  });

  testWidgets('previews the QR activation review flow', (tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.enterText(
      find.widgetWithText(TextField, 'Builder name'),
      'Jordan Rivers',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Phone number with country code'),
      '+959123456789',
    );
    await tester.drag(find.byType(ListView), const Offset(0, -260));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start activation'));
    await tester.pumpAndSettle();

    expect(find.text('Activation Request'), findsOneWidget);
    expect(find.text('Your activation request'), findsOneWidget);
    expect(find.text('Scan activation QR'), findsOneWidget);
    expect(find.text('Import QR image'), findsOneWidget);

    await tester.drag(find.byType(ListView).last, const Offset(0, -420));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Import QR image'));
    await tester.pumpAndSettle();

    expect(find.text('Review Activation'), findsOneWidget);
    expect(find.text('Activation costs covered'), findsOneWidget);
    expect(find.textContaining('XLM'), findsNothing);
    expect(find.textContaining('trustline'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('Approve and activate'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Approve and activate'));
    await tester.pumpAndSettle();
    expect(find.text('Activation is being verified.'), findsOneWidget);
  });

  testWidgets('cancels an activation request after confirmation', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await _openActivationRequest(tester);

    await tester.ensureVisible(find.text('Cancel activation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel activation'));
    await tester.pumpAndSettle();
    expect(find.text('Cancel activation?'), findsOneWidget);
    await tester.tap(find.text('Cancel activation').last);
    await tester.pumpAndSettle();

    expect(fakeWalletSdk.cancelCalls, 1);
    expect(find.text('Rewards is not activated'), findsOneWidget);
  });

  testWidgets('keeps the request available when cancellation fails', (
    tester,
  ) async {
    fakeWalletSdk.cancelShouldFail = true;
    await tester.pumpWidget(const MyApp());
    await _openActivationRequest(tester);

    await tester.ensureVisible(find.text('Cancel activation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel activation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel activation').last);
    await tester.pumpAndSettle();

    expect(fakeWalletSdk.cancelCalls, 1);
    expect(find.text('Cancel activation'), findsOneWidget);
    expect(find.text('Rewards is not activated'), findsNothing);
    expect(
      find.text("We couldn't cancel this activation. Try again."),
      findsOneWidget,
    );
  });

  testWidgets('previews App Master activation package flow', (tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.byTooltip('Open App Master'));
    await tester.pumpAndSettle();

    expect(find.text('App Master'), findsOneWidget);
    expect(find.text('Activation capacity'), findsOneWidget);
    expect(find.text('13 Builders'), findsOneWidget);
    expect(find.text('My Rewards'), findsOneWidget);
    expect(find.textContaining('XLM'), findsNothing);

    await tester.tap(find.text('Advanced'));
    await tester.pumpAndSettle();
    expect(find.text('NOWNodes configuration'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'NOWNodes API key'),
      'test-api-key',
    );
    expect(Get.find<AppMasterController>().nowNodesApiKey, 'test-api-key');
    await tester.ensureVisible(find.text('Save and verify settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save and verify settings'));
    await tester.pumpAndSettle();
    expect(find.text('Configuration v1 ready'), findsWidgets);
    expect(fakeWalletSdk.providerSaveCalls, 1);
    expect(fakeWalletSdk.lastProviderInput?.apiKey, 'test-api-key');
    expect(Get.find<AppMasterController>().nowNodesApiKey, isEmpty);
    await tester.scrollUntilVisible(
      find.text('Configuration v1 ready').last,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Configuration v1 ready'), findsWidgets);
    expect(find.text('Environment'), findsWidgets);
    expect(find.textContaining('XLM'), findsNothing);

    await tester.fling(
      find.byType(ListView).first,
      const Offset(0, 1200),
      2000,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Overview'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -480));
    await tester.pumpAndSettle();
    expect(find.text('Builder access'), findsOneWidget);
    expect(find.text('Jordan Rivers'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Import QR image'),
      -220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Import QR image'));
    await tester.pumpAndSettle();

    expect(find.text('Activate Builder'), findsOneWidget);
    expect(find.text('Activation package'), findsOneWidget);
    expect(find.text('Noah Williams'), findsOneWidget);
    expect(find.text('+95912345678'), findsOneWidget);
    expect(find.text('ACT-TEST-01'), findsOneWidget);
    await tester.drag(find.byType(ListView).last, const Offset(0, -420));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Create activation QR'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create activation QR'));
    await tester.pumpAndSettle();

    expect(find.text('Activation QR'), findsOneWidget);
    expect(find.text('Save QR image'), findsOneWidget);
  });

  testWidgets('clears the NOWNodes key and shows a safe SDK failure', (
    tester,
  ) async {
    fakeWalletSdk.providerSaveShouldFail = true;
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.byTooltip('Open App Master'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Advanced'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'NOWNodes API key'),
      'rejected-test-key',
    );
    await tester.ensureVisible(find.text('Save and verify settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save and verify settings'));
    await tester.pumpAndSettle();

    expect(fakeWalletSdk.providerSaveCalls, 1);
    expect(Get.find<AppMasterController>().nowNodesApiKey, isEmpty);
    expect(find.text('The NOWNodes API key was not accepted.'), findsOneWidget);
    expect(find.textContaining('rejected-test-key'), findsNothing);
  });

  testWidgets('handles cancelled and unreadable QR image imports safely', (
    tester,
  ) async {
    fakeQrImagePicker.path = null;
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.byTooltip('Open App Master'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Import QR image'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Import QR image'));
    await tester.pumpAndSettle();
    expect(find.textContaining("couldn't find"), findsNothing);

    fakeQrImagePicker.path = 'unreadable.png';
    fakeQrImageDecoder.capture = const BarcodeCapture();
    await tester.ensureVisible(find.text('Import QR image'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Import QR image'));
    await tester.pumpAndSettle();
    expect(
      find.text("We couldn't find a readable activation QR in that image."),
      findsOneWidget,
    );
  });

  testWidgets('shows a safe camera permission message', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.byTooltip('Open App Master'));
    await tester.pumpAndSettle();
    Get.find<AppMasterController>().handleQrFailure(
      QrInputFailure.permissionDenied,
    );
    await tester.pump();

    expect(
      find.text('Camera access was denied. Import a QR image instead.'),
      findsOneWidget,
    );
  });

  testWidgets('keeps an invalid activation request out of review', (
    tester,
  ) async {
    fakeWalletSdk.inspectShouldFail = true;
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.byTooltip('Open App Master'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Import QR image'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Import QR image'));
    await tester.pumpAndSettle();

    expect(find.text('Activate Builder'), findsNothing);
    expect(
      find.text("We couldn't verify this activation request."),
      findsOneWidget,
    );
  });

  testWidgets('offers the restored Builder review after restart', (
    tester,
  ) async {
    fakeWalletSdk.restoredReview = _FakeWalletSdk.review;
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.byTooltip('Open App Master'));
    await tester.pumpAndSettle();

    expect(find.text('Resume Builder review'), findsOneWidget);
    await tester.tap(find.text('Resume Builder review'));
    await tester.pumpAndSettle();
    expect(find.text('Noah Williams'), findsOneWidget);
    expect(find.text('ACT-TEST-01'), findsOneWidget);
  });

  testWidgets('imports distributor secret once and clears the field', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.byTooltip('Open App Master'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Advanced'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Distributor account'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Distributor secret key'),
      'private-test-value',
    );
    await tester.ensureVisible(find.text('Import and verify account'));
    await tester.tap(find.text('Import and verify account'));
    await tester.pumpAndSettle();
    expect(find.text('Import distributor account?'), findsOneWidget);
    await tester.tap(find.text('Import securely'));
    await tester.pumpAndSettle();

    expect(find.text('Distributor verified'), findsOneWidget);
    expect(find.text('GABCDE…UVWXYZ'), findsOneWidget);
    expect(Get.find<AppMasterController>().distributorSecret, isEmpty);
    expect(find.textContaining('private-test-value'), findsNothing);
  });
}

final class _FakeWalletSdk implements WalletSdk {
  int cancelCalls = 0;
  bool cancelShouldFail = false;
  int providerSaveCalls = 0;
  ProviderConfigurationInput? lastProviderInput;
  bool providerSaveShouldFail = false;
  bool inspectShouldFail = false;
  ActivationRequestReview? restoredReview;

  static final ActivationRequestReview review = ActivationRequestReview(
    requestId: 'ACT-TEST-01',
    builder: const BuilderIdentity(
      displayName: 'Noah Williams',
      phone: '+95912345678',
    ),
    expiresAt: DateTime(2030, 1, 1, 12),
    setupSteps: const <String>[
      'Set up Rewards',
      'Enable Rewards access',
      'Add starting Rewards',
    ],
  );

  static final ActivationRequestView request = ActivationRequestView(
    requestId: 'ACT-TEST-01',
    qrValue: 'thebuilderpros://rewards/activate/ACT-TEST-01',
    expiresAt: DateTime(2030, 1, 1, 12),
    builder: const BuilderIdentity(
      displayName: 'Jordan Rivers',
      phone: '+959123456789',
    ),
  );

  @override
  Future<ConfigurationOutcome> applyConfigurationUpdate(
    String updateId,
  ) async => const ConfigurationOutcome(
    status: ProviderConfigurationStatus.notConfigured(),
  );

  @override
  Future<ConfigurationRequestView> createConfigurationRequest() async =>
      ConfigurationRequestView(
        requestId: 'CFG-TEST-01',
        qrValue: 'opaque-configuration-request',
        expiresAt: DateTime(2030),
      );

  @override
  Future<ConfigurationUpdateView> createConfigurationUpdate(
    String requestId,
  ) async => ConfigurationUpdateView(
    updateId: 'UPD-TEST-01',
    requestId: requestId,
    qrValue: 'opaque-configuration-update',
    expiresAt: DateTime(2030),
  );

  @override
  Future<ConfigurationRequestReview> inspectConfigurationRequest(
    String qrValue,
  ) async => ConfigurationRequestReview(
    requestId: 'CFG-TEST-01',
    currentVersion: 1,
    environment: ProviderEnvironment.test,
    expiresAt: DateTime(2030),
  );

  @override
  Future<ConfigurationReview> inspectConfigurationUpdate(
    String qrValue,
  ) async => ConfigurationReview(
    updateId: 'UPD-TEST-01',
    version: 2,
    environment: ProviderEnvironment.test,
    endpointHost: 'xlm.nownodes.io',
    expiresAt: DateTime(2030),
  );

  @override
  Future<void> cancelActivation() async {
    cancelCalls++;
    if (cancelShouldFail) {
      throw const WalletSdkException(
        code: WalletSdkFailureCode.cancellationFailed,
        safeMessage: "We couldn't cancel this activation. Try again.",
        canRetry: true,
      );
    }
  }

  @override
  Future<ProviderConfigurationStatus> getProviderConfigurationStatus() async =>
      const ProviderConfigurationStatus.notConfigured();

  @override
  Future<DistributorAuthorityStatus> getDistributorAuthorityStatus() async =>
      const DistributorAuthorityStatus.notConfigured();

  @override
  Future<AppMasterOverview> getAppMasterOverview() async => AppMasterOverview(
    activationCapacity: 13,
    rewardsAvailable: '18,400',
    serviceStatus: 'Ready for activations',
    updatedAt: DateTime.utc(2026, 9, 19, 16),
  );

  @override
  Future<DistributorAuthorityStatus> importDistributorSecret(
    String secret,
  ) async => const DistributorAuthorityStatus(
    state: DistributorAuthorityState.ready,
    maskedAccountId: 'GABCDE…UVWXYZ',
    environment: ProviderEnvironment.production,
  );

  @override
  Future<void> removeDistributorAuthority() async {}

  @override
  Future<ActivationRequestReview> inspectBuilderRequest(String qrValue) async {
    if (inspectShouldFail) {
      throw const WalletSdkException(
        code: WalletSdkFailureCode.invalidActivationRequest,
        safeMessage: "We couldn't verify this activation request.",
        canRetry: false,
      );
    }
    return review;
  }

  @override
  Future<ActivationRequestReview?> restoreInspectedBuilderRequest() async =>
      restoredReview;

  @override
  Future<ActivationResponseView> approveBuilderRequest(
    String requestId,
  ) async => ActivationResponseView(
    responseId: 'RES-TEST-01',
    requestId: requestId,
    qrValue: 'opaque-activation-response',
    expiresAt: DateTime(2030, 1, 1, 12, 5),
  );

  @override
  Future<ActivationReview> inspectActivationResponse(String qrValue) async =>
      ActivationReview(
        responseId: 'RES-TEST-01',
        requestId: review.requestId,
        expiresAt: DateTime(2030, 1, 1, 12, 5),
        preparedBy: 'GABCDE…UVWXYZ',
        setupSteps: const <String>[
          'Activation costs covered',
          'Rewards access ready',
          'Starting Rewards: 1',
        ],
      );

  @override
  Future<ActivationOutcome> approveActivation(String responseId) async =>
      ActivationOutcome(
        responseId: responseId,
        state: ActivationOutcomeState.submitted,
        message: 'Activation submitted. Verifying Rewards setup…',
      );

  @override
  Future<WalletActivationStatus> reconcileActivation() async =>
      const WalletActivationStatus(
        state: WalletActivationState.pending,
        message: 'Activation is being verified.',
      );

  @override
  Future<WalletActivationStatus> getActivationStatus() async =>
      const WalletActivationStatus.notActivated();

  @override
  Future<ActivationRequestView?> restoreActivationRequest() async => null;

  @override
  Future<ActivationRequestView> startActivation(
    BuilderIdentity builder,
  ) async => request;

  @override
  Future<ProviderConfigurationOutcome> saveAppMasterProviderConfiguration(
    ProviderConfigurationInput input,
  ) async {
    providerSaveCalls++;
    lastProviderInput = input;
    if (providerSaveShouldFail) {
      throw const WalletSdkException(
        code: WalletSdkFailureCode.providerUnauthorized,
        safeMessage: 'The NOWNodes API key was not accepted.',
        canRetry: true,
      );
    }
    return ProviderConfigurationOutcome(
      status: ProviderConfigurationStatus(
        state: ProviderConfigurationState.ready,
        environment: input.environment,
        version: input.version,
        endpointHost: Uri.parse(input.endpoint).host,
        lastCheckedAt: DateTime.utc(2026, 9, 18, 12),
      ),
    );
  }
}

final class _FakeQrImagePicker implements QrImagePicker {
  String? path = 'activation-qr.png';

  @override
  Future<String?> pickImagePath() async => path;
}

final class _FakeQrImageDecoder implements QrImageDecoder {
  BarcodeCapture? capture = const BarcodeCapture(
    barcodes: <Barcode>[Barcode(rawValue: 'opaque-activation-request')],
  );

  @override
  Future<BarcodeCapture?> decode(String path) async => capture;
}

Future<void> _openActivationRequest(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(TextField, 'Builder name'),
    'Jordan Rivers',
  );
  await tester.enterText(
    find.widgetWithText(TextField, 'Phone number with country code'),
    '+959123456789',
  );
  await tester.drag(find.byType(ListView), const Offset(0, -260));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Start activation'));
  await tester.pumpAndSettle();
}
