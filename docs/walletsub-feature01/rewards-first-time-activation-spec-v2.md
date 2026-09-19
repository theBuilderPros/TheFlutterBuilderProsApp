# Rewards First-Time Activation Specification V2

## Product decision

First-time Rewards activation is a phone-to-phone QR handshake between the Builder
App and App Master App. Both people use simple Rewards language. All implementation
complexity belongs inside the Wallet SDK.

## End-to-end experience

0. The App Master saves and verifies the NOWNodes configuration in Advanced.
1. The Builder enters their name and phone number.
2. The Builder taps **Start activation**.
3. The app asks the Wallet SDK to prepare an activation request.
4. The Builder App displays the request QR.
5. The App Master scans the QR or imports its image.
6. The App Master App asks the Wallet SDK to inspect the request.
7. The App Master reviews the Builder and setup summary and approves it.
8. The App Master App asks the Wallet SDK to prepare the response QR, including
   the encrypted device-bound provider configuration.
9. The Builder scans the response QR or imports its image.
10. The Builder App asks the Wallet SDK to inspect the response.
11. The Builder reviews the summary and approves activation.
12. The Wallet SDK installs the provider configuration, completes activation, and
    verifies the result.
13. The Builder App shows the verified Rewards outcome.

## Application boundary

The Flutter application may know only:

- Builder identity;
- activation request ID;
- safe QR content supplied by the Wallet SDK;
- expiry and display status;
- safe review rows;
- activation progress; and
- safe success or failure results.

The Flutter application must not construct, interpret, modify, store, or log the
protected contents used by the Wallet SDK.

## Simple Wallet SDK interface

```dart
abstract interface class WalletSdk {
  Future<ActivationRequestView> startActivation(BuilderIdentity builder);
  Future<ActivationRequestReview> inspectBuilderRequest(String qrValue);
  Future<ActivationResponseView> approveBuilderRequest(String requestId);
  Future<ActivationReview> inspectActivationResponse(String qrValue);
  Future<ActivationOutcome> approveActivation(String responseId);
  Future<ActivationStatus> getActivationStatus();
  Future<void> cancelActivation();
}
```

These are application-facing types. Their fields contain only values required to
render the interface. The SDK never returns protected credentials or provider data.

## Required outcomes

- `notActivated`
- `requestReady`
- `waitingForResponse`
- `readyForReview`
- `working`
- `verifying`
- `activated`
- `retryableFailure`
- `restartRequired`

Each failure contains a stable code for application branching and a safe message
for display. Provider-specific failures never cross the SDK boundary.

## Safety rules

- QR scanning and QR-image import use the same SDK inspection method.
- A QR is never acted on before SDK inspection and human review.
- The Builder and App Master approve only on their own phones.
- Protected credentials never cross between phones.
- Repeated, expired, mismatched, modified, or wrong-purpose QR content is rejected.
- An uncertain result remains in verification until the SDK establishes the final
  outcome.
- Success is shown only after `approveActivation()` returns `activated`.

## App Master surfaces

- **Overview:** activation capacity, Rewards availability, and Builder access.
- **Activate Builder:** safe Builder and setup review.
- **Activation QR:** QR display and image save.
- **Advanced:** safe service health plus masked NOWNodes endpoint/API-key setup and
  rotation controls for the App Master.
- **My Rewards:** the same Rewards experience used by a Builder.

Provider configuration is the only implementation-specific setting exposed in
Advanced. Its key is masked, submitted directly to the Wallet SDK, cleared from
the field, and never returned to the application.

## Acceptance criteria

- The two phones complete the experience using QR only.
- Application code uses only `WalletSdk` and safe SDK models.
- No protected credential crosses devices or enters Flutter presentation state.
- No provider-specific terminology appears in screens, controllers, routes,
  application models, analytics, or ordinary logs.
- Success, cancellation, expiry, mismatch, modification, repetition, interruption,
  and uncertain-result tests pass.
