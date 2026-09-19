# Wallet Sub-Feature 01 — Reference Implementation Plan

The application integrates Rewards through one small Wallet SDK facade. Junior
Flutter developers work with product concepts only; SDK adapters own every
security-sensitive and provider-specific detail.

The first production slice is defined in
`05-not-activated-screen-implementation-plan.md`.

## Dependency direction

```text
Screen -> Controller -> WalletSdk -> private SDK implementation
```

Only `WalletSdk` and its safe models are public to the application. SDK internals
must not be imported from `lib/app/features/`.

## Public facade

```dart
abstract interface class WalletSdk {
  Future<ProviderConfigurationOutcome> saveAppMasterProviderConfiguration(
    ProviderConfigurationInput input,
  );
  Future<ProviderConfigurationStatus> getProviderConfigurationStatus();
  Future<ActivationRequestView> startActivation(BuilderIdentity builder);
  Future<ActivationRequestView?> restoreActivationRequest();
  Future<ActivationRequestReview> inspectBuilderRequest(String qrValue);
  Future<ActivationResponseView> approveBuilderRequest(String requestId);
  Future<ActivationReview> inspectActivationResponse(String qrValue);
  Future<ActivationOutcome> approveActivation(String responseId);
  Future<ActivationStatus> getActivationStatus();
  Future<void> cancelActivation();
}
```

## Safe public models

- `BuilderIdentity`: display name and normalized phone.
- `ActivationRequestView`: request ID, opaque QR value, created time, expiry.
- `ActivationRequestReview`: request ID, Builder summary, safe setup rows.
- `ActivationResponseView`: response ID, opaque QR value, expiry.
- `ActivationReview`: response ID, Builder summary, safe setup rows.
- `ActivationOutcome`: status, safe message, safe retry flag, support reference.
- `ActivationStatus`: application state needed for routing and restoration.
- `ProviderConfigurationInput`: App Master-only NOWNodes endpoint, API key, environment, and next version. The controller passes it directly to the SDK and clears the key field.
- `ProviderConfigurationStatus`: safe health, version, and rotation status; it never returns the API key.

Use immutable models and stable enums. Do not expose generic maps, plugin objects,
provider responses, protected credentials, or raw exceptions.

## Error contract

All SDK calls return typed results or throw one documented `WalletSdkException`
containing:

```text
code
safeMessage
canRetry
supportReference (optional)
```

Controllers branch on `code` or `canRetry`; they never parse message text. Detailed
diagnostics stay inside the SDK's redacted diagnostic channel.

## Delivery order

1. Add the public facade, safe models, result codes, and a fake SDK for tests.
2. Refactor controllers to depend only on `WalletSdk`.
3. Implement App Master NOWNodes validation, health check, and protected storage through the facade.
4. Implement Start activation and restoration through the facade.
5. Replace placeholder request QR with the opaque SDK value.
6. Implement request scan and image import through one inspection method.
7. Implement App Master review and response QR, including encrypted device-bound configuration, through the facade.
8. Implement Builder response review, configuration installation, and activation completion through the facade.
9. Implement routine Rewards operations behind the same boundary.
10. Add interruption, repetition, expiry, mismatch, downgrade, and uncertain-result coverage.

## Enforcement

- Put public facade files in `wallet/sdk/` or a dedicated local package.
- Put SDK internals in a separate implementation library that the feature cannot
  import directly.
- Add an import-boundary test or lint check.
- Keep SDK construction inside dependency injection.
- Use `FakeWalletSdk` for controller and widget tests.
- Review any new public SDK field for product-language and data-minimization needs.

## Definition of done

No Builder screen, controller, route, or application model knows how Rewards
activation is implemented. NOWNodes appears only in App Master Advanced as masked
configuration input and safe status; validation, storage, header injection, QR
encryption, and rotation stay inside the SDK. A junior developer can build the UI
using the facade and safe models without learning protocol details.
