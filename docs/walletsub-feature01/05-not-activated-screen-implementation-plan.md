# Rewards — Not Activated: First Functional Implementation Plan

Status: first functional slice implemented and verified on 2026-09-18. App Master
request processing and Builder response completion remain future slices.

## Objective

Make **Start activation** real while keeping all implementation complexity inside
the Wallet SDK.

The application performs only four steps:

1. collect and validate name and phone;
2. call `WalletSdk.startActivation(builder)` once;
3. handle the safe SDK result; and
4. navigate to Activation Request with `ActivationRequestView`.

## Public types used by the feature

```dart
abstract interface class WalletSdk {
  Future<ActivationRequestView> startActivation(BuilderIdentity builder);
  Future<ActivationRequestView?> restoreActivationRequest();
  Future<void> cancelActivation();
}

class BuilderIdentity {
  final String displayName;
  final String phone;
}

class ActivationRequestView {
  final String requestId;
  final String qrValue;
  final DateTime expiresAt;
  final BuilderIdentity builder;
}
```

Production models should be immutable and use `const` constructors where possible.
The request QR value is opaque: application code may display or copy it but never
parse, alter, or make decisions from it.

## Controller behavior

Replace `openActivation()` with `startActivation()`.

Controller state:

- `idle`
- `working`
- `requestReady`
- `failure`

Flow:

```text
validate fields
  -> set working
  -> call WalletSdk.startActivation()
  -> retain ActivationRequestView
  -> navigate on success
  -> show safe SDK failure on failure
  -> return to idle
```

Use an in-flight guard so rapid taps produce one SDK call. The controller must not
generate identifiers, create QR content, access storage, or catch implementation-
specific exceptions.

## Screen behavior

### Idle

- Name and phone are editable.
- Start activation is enabled.

### Working

- Disable fields and Start activation.
- Show **Preparing your activation request…**.
- Keep the user on the same screen.

### Success

- Navigate only after the SDK returns `ActivationRequestView`.
- Activation Request renders a real QR using `qrValue`.
- Display `requestId` and expiry in friendly language.
- Copy copies exactly `qrValue`.

### Failure

- Stay on Not Activated.
- Re-enable the form.
- Show only `WalletSdkException.safeMessage`.
- Offer retry only when `canRetry` is true.

## Feature structure

```text
lib/app/features/wallet/
|-- sdk/
|   |-- wallet_sdk.dart
|   |-- wallet_sdk_models.dart
|   `-- wallet_sdk_exception.dart
|-- controller/
|   `-- wallet_controller.dart
|-- binding/
|   `-- wallet_binding.dart
`-- screen/activation/
    |-- wallet_not_activated_screen.dart
    `-- wallet_activation_request_screen.dart
```

The private SDK implementation may live behind this public folder or in a separate
package. Feature files may import only the public facade and safe model files.

## Implementation order

1. Add `WalletSdk`, safe models, and stable failure codes.
2. Add `FakeWalletSdk` for deterministic tests.
3. Register `WalletSdk` in `WalletBinding`.
4. Add typed controller state and `startActivation()`.
5. Connect loading, success, and failure presentation.
6. Replace mock request ID/content with `ActivationRequestView`.
7. Render the real QR from the opaque SDK value.
8. Restore an existing request through `restoreActivationRequest()` at startup.
9. Add an import-boundary check preventing feature code from using SDK internals.
10. Run formatting, analysis, unit tests, widget tests, and physical-device checks.

## Tests

### Controller

- invalid fields make no SDK call;
- a valid submission calls `startActivation()` once;
- repeated taps while working do not create another call;
- success stores only the safe request view and navigates;
- safe failure is displayed and retry follows `canRetry`;
- restoration resumes a valid request;
- cancellation calls the SDK and returns to Not Activated.

### Widget

- working state disables fields and action;
- success displays the real QR and request ID;
- copy uses the opaque SDK value unchanged;
- failure remains on the screen;
- no provider-specific terminology is rendered.

### Boundary

- feature imports are limited to the public Wallet SDK facade;
- public SDK models contain no protected or provider-specific fields;
- logs, analytics, clipboard labels, and screen state contain no protected data.

## Exit criteria

Start activation works through the simple Wallet SDK interface, produces one
restorable request, renders its QR, handles safe failures, and exposes no internal
activation concept to the Flutter feature or junior developer.
