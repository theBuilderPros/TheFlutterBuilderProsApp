# Wallet Sub-Feature 01 — User Stories

## Builder activation

### US-01 — Start activation

As a Builder, I enter my name and phone and start activation.

- The app validates basic input and calls `WalletSdk.startActivation()` once.
- The action shows progress and prevents duplicate taps.
- The SDK returns either a safe request view or a safe failure.

### US-02 — Share the request QR

As a Builder, I show the SDK-provided request QR to an App Master.

- The application treats QR content as opaque.
- Copy uses exactly the value returned by the SDK.
- An unexpired pending request can be restored through the SDK.

### US-03 — Review the Builder request

As an App Master, I scan or import the request and review the Builder.

- Both input methods call `WalletSdk.inspectBuilderRequest()`.
- The app renders only the returned safe review.
- Invalid input receives a stable safe failure.

### US-04 — Prepare the activation QR

As an App Master, I approve a valid Builder request.

- The app calls `WalletSdk.approveBuilderRequest()`.
- The SDK returns a response ID, QR value, expiry, and safe status.
- The application does not inspect or modify the QR value.

### US-05 — Approve activation

As a Builder, I scan/import the response, review it, and approve it.

- Inspection uses `WalletSdk.inspectActivationResponse()`.
- Approval uses `WalletSdk.approveActivation()`.
- Cancellation performs no completion action.

### US-06 — See a verified result

As a Builder, I see success only when the SDK returns `activated`.

- An uncertain result shows safe verification progress.
- Retry is offered only when the SDK marks it safe.

## App Master operations

### US-07 — Monitor activation capacity

As an App Master, I see safe capacity and Rewards summaries supplied by the SDK.

### US-08 — Monitor Builder access

As an App Master, I see Builder access status and Rewards balances without internal
implementation details.

### US-09 — Inspect support information

As an App Master, I open Advanced to save the NOWNodes endpoint/API key and see
environment, configuration version, service health, last check, and safe support
references supplied by the SDK.

- The API key field is masked.
- Save passes the value directly to the Wallet SDK and clears the field.
- The SDK health-checks and protects the configuration before reporting success.
- Activation response creation is unavailable until configuration is healthy.

### US-10 — Use My Rewards

As an App Master user, I use the shared Rewards experience without transferring
App Master authority into the Builder controller.

## Cross-cutting rules

- Flutter code depends only on the Wallet SDK facade and safe models.
- QR values are opaque outside the SDK.
- Protected credentials never enter application state, screenshots, clipboard,
  analytics, crash reports, or ordinary logs.
- Mock screens never claim real SDK completion.
