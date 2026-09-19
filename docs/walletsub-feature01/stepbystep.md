# Wallet SDK Step-by-Step Implementation Plan

## Purpose

Implement the Rewards wallet one independently testable slice at a time. After each
step, development stops for review and device testing before the next step begins.
No step may be described as functional until its automated checks and stated manual
test pass.

The Flutter application may import only `lib/wallet_sdk/wallet_sdk.dart`. Stellar,
NOWNodes, cryptography, protected credentials, QR schemas, and transport details
remain private under `lib/wallet_sdk/src/`.

## Current baseline

### Implemented

- Public `WalletSdk` facade containing:
  - `startActivation()`
  - `restoreActivationRequest()`
  - `cancelActivation()`
- Safe `BuilderIdentity`, `ActivationRequestView`, and error types.
- Builder detail validation.
- A 15-minute restorable activation request.
- Secure storage of the generated Builder secret.
- Ordinary persistence of safe pending-request state.
- A real QR rendered from the opaque request value.
- Cancellation and rollback for the first request slice.

### Temporary implementation that must be replaced

- `stellar_flutter_sdk` currently generates the Builder keypair.
- Activation QR encoding is inline in `DefaultWalletSdk`.
- Storage, clock, random generation, and QR encoding are not yet separated into
  private SDK services.
- App Master NOWNodes saving is a UI mock.
- The remaining facade operations and private internals are specifications only.

## Working protocol

For every step:

1. Implement only that step and its supporting tests.
2. Update `context/current-state.md` and `context/progress-tracker.md` with the exact
   implemented boundary.
3. Format changed Dart files.
4. Run `flutter analyze` and `flutter test`.
5. Build Android only when dependencies, permissions, plugins, or native settings
   change.
6. Provide the user with a short manual test script.
7. Wait for user verification before starting the next step.

Use testnet and non-production NOWNodes credentials until the full activation flow
has passed two-device testing. Never commit a real API key, seed, or signed envelope.

## Step 1 — Private SDK foundation and native key replacement

Status: completed. Automatically verified and confirmed working by user device test
on 2026-09-18.

### Goal

Remove the full Stellar SDK dependency and preserve the currently working Builder
activation-request behavior.

### Implementation

- Split `DefaultWalletSdk` into focused private services:
  - activation request service;
  - activation store;
  - credential store;
  - clock and secure-random abstractions; and
  - activation QR codec.
- Add a reviewed generic Ed25519 implementation.
- Implement private Stellar StrKey public-address and secret-seed encoding:
  version bytes, Base32, CRC16-XModem, and validation.
- Generate the key using operating-system secure randomness.
- Remove `stellar_flutter_sdk` from `pubspec.yaml`.
- Preserve the existing public facade and UI behavior.

### Automated acceptance

- Official valid and invalid StrKey fixtures pass.
- CRC16 and Base32 round-trip tests pass.
- Generated public addresses and seeds decode and validate.
- Existing request create, restore, expiry, rollback, and cancel tests pass.
- No source file imports `stellar_flutter_sdk`.

### User test

1. Enter Builder name and international phone number.
2. Start activation.
3. Confirm the request QR and request ID appear.
4. Close and reopen the app; confirm the same unexpired request returns.

Cancellation exists in the SDK but was not wired to the screen in Step 1. That UI
work is included in Step 2.

### Exit condition

The existing first slice behaves the same without `stellar_flutter_sdk`.

## Step 2 — Provider configuration models and protected store

Status: completed. Automatically verified and confirmed working by user device test
on 2026-09-18.

### Goal

Add the real SDK contract for App Master NOWNodes configuration without making a
network request yet.

### Implementation

- Add safe public types:
  - `ProviderConfigurationInput`;
  - `ProviderConfigurationOutcome`;
  - `ProviderConfigurationStatus`; and
  - stable provider-configuration failure codes.
- Add `saveAppMasterProviderConfiguration()` and
  `getProviderConfigurationStatus()` to the facade and fake SDK.
- Add private typed configuration, validation policy, and protected store.
- Accept only HTTPS endpoints outside explicit local-test environments.
- Allow only approved provider header names; use `api-key` for NOWNodes.
- Enforce endpoint, key, environment, and value-size limits.
- Never return the API key from the SDK.
- Store only safe version/health metadata in ordinary persistence.
- Add **Cancel activation** to the Builder Activation Request screen.
- Require confirmation, call `WalletSdk.cancelActivation()`, clear controller-held
  request state, and return to the not-activated screen only after cleanup succeeds.
- Prevent duplicate cancellation taps and show only a safe retryable failure when
  cleanup fails.

### Automated acceptance

- Invalid schemes, hosts, header names, empty keys, and oversized values fail.
- Save/read/delete and failed-write rollback tests pass.
- Public results and logs contain no API key.
- Feature code still imports no private SDK file.
- Controller and widget tests prove cancellation calls the SDK once, returns to the
  not-activated screen on success, and remains retryable on failure.

### User test

1. From an active request, tap **Cancel activation** and confirm the action.
2. Confirm the app returns to the not-activated screen.
3. Start again and confirm a different request is created.
4. Separately, a developer test verifies that provider configuration can be stored
   and that only safe status is returned; provider configuration is not wired to
   App Master UI until Step 4.

### Exit condition

The protected configuration boundary exists, but status remains unverified until
Step 3 adds the health check.

## Step 3 — Direct Horizon HTTP client and NOWNodes health check

Status: implemented and automatically verified on 2026-09-18. A real NOWNodes-key
device test is deferred to Step 4, where App Master Advanced is connected to these
SDK calls.

### Goal

Validate a candidate NOWNodes configuration through direct HTTP calls without a
Stellar SDK.

### Implementation

- Add a private Horizon-compatible HTTP adapter.
- Normalize and lock the configured base origin.
- Inject `api-key` only inside the HTTP adapter.
- Implement `GET /` for service and network identity checks.
- Add bounded connect/read/total timeouts and response-size limits.
- Require the expected JSON content type and parse into private typed DTOs.
- Map timeout, unauthorized, rate-limit, invalid-network, and server failures to
  safe SDK errors.
- Redact headers, credentials, query strings, and response bodies from diagnostics.
- Save a candidate configuration only after a successful health check.
- Preserve the previous healthy configuration on every failure.

### Automated acceptance

- HTTP contract tests cover healthy, unauthorized, `429`, `5xx`, timeout,
  malformed JSON, wrong content type, oversized response, and wrong network.
- Tests prove the `api-key` header is sent but never logged or returned.
- Transactional replacement tests prove the previous configuration survives a
  failed health check.

### User test

Use a non-production NOWNodes key to run one SDK-level health check. Confirm a valid
key becomes `ready` and an invalid key produces only a safe error.

### Exit condition

The SDK can verify and protect a NOWNodes configuration.

## Step 4 — Connect App Master Advanced to the real SDK

**Implementation status:** Complete and device verified on 2026-09-19. A live
NOWNodes check found and fixed its Horizon `application/hal+json` response
compatibility. The temporarily exposed test key was removed and must remain rotated.

### Goal

Replace the current presentation-only save action with the real SDK operation.

### Implementation

- Make `AppMasterController` depend only on `WalletSdk`.
- Pass endpoint and API-key input directly to
  `saveAppMasterProviderConfiguration()`.
- Clear the API-key field immediately after the SDK call completes, whether it
  succeeds or fails.
- Show only safe loading, ready, retryable failure, configuration version, and
  last-check status.
- Restore safe status with `getProviderConfigurationStatus()` when Advanced opens.
- Prevent duplicate save taps.
- Keep the key out of reactive state after submission, navigation arguments,
  ordinary preferences, clipboard, analytics, and diagnostics.

### Automated acceptance

- Controller and widget tests cover success, invalid input, unauthorized key,
  timeout, duplicate taps, restoration, and field clearing.
- Tests prove no key text appears after submission.

### User test

1. Open App Master → Advanced.
2. Enter the NOWNodes endpoint and a test key.
3. Save and confirm the field clears.
4. Confirm `Configuration ready` and a version appear.
5. Restart the app and confirm safe readiness returns without revealing the key.
6. Try an invalid key and confirm the last healthy configuration remains active.

Use a disposable/non-production NOWNodes API key supplied outside source control.
Remove or rotate it immediately if it is ever pasted into a tracked document.
### Exit condition

App Master NOWNodes configuration is functional, health-checked, and protected.

## Step 5 — Device configuration identity and activation request v2

**Implementation status:** Complete and device verified on 2026-09-19.

### Goal

Bind future encrypted configuration to one Builder installation.

### Implementation

- Create a separate X25519 device configuration identity.
- Store its private key in protected storage.
- Add opaque device ID and device configuration public key to activation request
  schema version 2.
- Move canonical JSON encoding, size checks, type/version checks, and expiry rules
  into the private activation QR codec.
- Migrate or safely invalidate pending version-1 requests.
- Keep all new fields opaque to Flutter features.

### Automated acceptance

- Canonical encoding is deterministic.
- Malformed, oversized, unsupported-version, expired, and altered requests fail.
- Restored requests retain the same device binding.
- Private device material never enters the QR or ordinary storage.

### User test

Create and restore a request as in Step 1. Visually, the flow should remain
unchanged; the new QR must still scan reliably from another phone.

### Exit condition

Each activation request can receive configuration encrypted only for its device.

## Step 6 — QR scanning and image import infrastructure

**Implementation status:** Complete and device verified on 2026-09-19.

### Goal

Replace the App Master scan/import presentation actions with actual QR decoding.

### Implementation

- Add camera QR scanning behind a focused adapter.
- Add QR decoding from a selected image behind the same input boundary.
- Request camera/photo permissions only when the related action is used.
- Pass decoded text unchanged to `inspectBuilderRequest()`.
- Do not parse QR schemas in widgets or controllers.
- Add cancel, permission-denied, unreadable-image, and multiple-code handling.

### Automated acceptance

- Adapter tests return exact decoded values.
- Widget tests cover scan, import, cancel, denied permission, and unreadable input.
- Feature code contains no activation payload parsing.

### User test

Display a Builder request QR on phone A. Scan it and import a screenshot of it on
phone B. Both paths must reach the same App Master review.

### Exit condition

The App Master app can obtain an opaque request value from camera or image.

## Step 7 — App Master request inspection

**Implementation status:** Complete and device verified on 2026-09-19.

### Goal

Implement `inspectBuilderRequest()` and display a safe Builder review.

### Implementation

- Add `ActivationRequestReview` to the public API.
- Validate QR type, schema, size, environment, expiry, challenge, request ID,
  Builder fields, activation address, device ID, and device public key.
- Add a replay/request store and reject previously consumed requests.
- Return only Builder identity and safe setup rows.
- Persist enough safe state for approval restoration.

### Automated acceptance

- Valid, malformed, expired, wrong-environment, altered, repeated, and oversized
  request tests pass.
- Public review models expose no activation address or device key.

### User test

Scan/import the Builder request and verify the correct Builder name, phone, expiry,
and plain-language setup summary. Reusing an expired or consumed request must fail
safely.

### Exit condition

App Master can safely inspect a real Builder request.

## Step 8 — App Master authority and distributor credential provisioning

**Implementation status:** Complete and device verified on 2026-09-19.

### Goal

Establish the local signing authority needed to fund Builder accounts.

### Approved decision

Use the familiar LOBSTR-style existing-wallet import interaction: App Master types
or pastes the 56-character Stellar distributor secret into a masked field in
Advanced. The SDK validates it, derives its public account, verifies that account
through the configured environment, writes it to platform-protected storage only
after verification succeeds, and clears transient input on every result. Only a
masked public account identifier returns to application code.

### Implementation

- Add an App Master authority service and protected credential store.
- Import or create the distributor credential through the approved ceremony.
- Derive and display only a masked public account identifier.
- Verify the credential against the configured environment.
- Add lock/removal/replacement operations and safe status.
- Ensure activation approval requires both healthy provider configuration and a
  verified distributor authority.

### Exit condition

The App Master device has a verified protected signing authority, with no secret
returned to application code.

## Step 9 — Read-only distributor status through direct HTTP

**Implementation status:** Complete and device verified on 2026-09-19.

### Goal

Make App Master capacity and Builder status data real before transaction building.

### Implementation

- Implement direct `GET /accounts/{account_id}` and `GET /fee_stats` calls.
- Parse balances, liabilities, sequence, and trustlines into private DTOs.
- Derive safe activation capacity and service status inside the SDK.
- Replace mock Advanced/overview capacity values with safe facade models.
- Keep all network and ledger terminology out of ordinary UI.

### User test

Open App Master overview and refresh. Confirm capacity and service status match the
configured test account while no XLM or protocol jargon leaks outside Advanced.

### Exit condition

The SDK can read the authoritative state required to prepare an activation.

## Step 10 — Version-pinned XDR and Stellar protocol core

**Implementation status:** Implemented and automated checks passed on
2026-09-19. This private SDK step has no visible UI change; it awaits the user's
gate confirmation before Step 11 begins.

### Goal

Implement only the protocol structures needed by this product without a full
Stellar SDK.

### Implementation

- Pin an official Stellar protocol version.
- Generate/derive Dart codecs from the official `.x` definitions.
- Add RFC 4506 primitives, bounds, discriminants, and padding.
- Implement StrKey validation, transaction hashing, signature hints, Ed25519
  signing/verification, and envelope signature preservation.
- Support only the exact envelope and operations required by activation:
  `createAccount`, `changeTrust`, and `payment`.
- Reject every unsupported or extra operation.

### Implemented boundary

- Pinned official Stellar XDR `v27.0` at commit
  `68fa1ac55692f68ad2a2ca549d0a283273554439`.
- Committed the activation-subset schema, deterministic Dart generator, and
  generated discriminants and limits.
- Added strict RFC 4506 big-endian primitives, bounded arrays and opaque values,
  canonical zero-padding checks, truncation checks, and trailing-byte rejection.
- Added a private classic V1 codec limited to Ed25519 accounts, no memo, optional
  time bounds, and `createAccount`, `changeTrust`, and `payment`. Other envelope,
  account, asset, extension, memo, precondition, and operation variants fail closed.
- Added network-passphrase hashing, signature hints, Ed25519 signing and
  verification, duplicate-signer rejection, and preservation of existing decorated
  signatures.
- This layer is not connected to activation approval. Step 11 owns policy, live
  sequence and fee reads, protected distributor signing, response encryption, and
  QR creation.

### Automated acceptance

- Official XDR and signature vectors pass byte-for-byte.
- Round-trip, malformed, truncation, bounds, and mutation tests pass.
- Generated code and generator are committed with the protocol version recorded.

### Exit condition

The SDK can safely build, inspect, hash, and sign the limited activation envelope.

### Review test

There is no new screen in this step. Confirm the automated protocol boundary and
that the existing app still opens normally. Step 11 must not begin before that
confirmation.

## Step 11 — Build and authorize the App Master activation response

**Implementation status:** Implemented and automated checks passed on
2026-09-19. Awaiting two-device user verification.

### Goal

Implement `approveBuilderRequest()` through response QR creation.

### Implementation

- Load fresh distributor sequence, balances, trustline state, and fee statistics.
- Enforce configured reserve, fee ceiling, Rewards asset, issuer, and starting
  amount policy.
- Build the atomic three-operation transaction in the required order.
- Inspect the completed structure against the allow-list before signing.
- Add the App Master signature through a protected signing handle.
- Encrypt the saved NOWNodes configuration to the Builder device using
  X25519 + HKDF-SHA256 + XChaCha20-Poly1305.
- Bind request, challenge, device, environment, version, issue time, and expiry.
- Authorize the complete response and encode an opaque response QR.
- Fail with `providerConfigurationRequired` unless configuration is healthy.
- Mark the request approved without marking it consumed until completion policy
  permits.

### Implemented policy

- The single spendable non-native distributor balance defines the Rewards code and
  issuer; zero or multiple candidates fail closed.
- Builder funding is 2.1 native units and starting Rewards is 1 unit.
- Fee is three times the greater of 100 or live p95, capped at 100,000 per
  operation; response lifetime is at most five minutes and never exceeds the
  request expiry.
- The response contains a distributor-signed three-operation V1 envelope and the
  active provider configuration encrypted for the requested device with
  X25519, HKDF-SHA256, and XChaCha20-Poly1305.
- The complete canonical response is authorized by the protected distributor key.

### User test

Approve the reviewed request on phone B. Confirm a response QR appears, can be
saved, contains no visibly exposed key, and an invalid/expired request cannot be
approved.

### Exit condition

App Master produces a real, partially signed, device-bound activation response.

## Step 12 — Builder response inspection

**Implementation status:** Implemented and automated checks passed on
2026-09-19. Awaiting two-device user verification.

### Goal

Implement `inspectActivationResponse()` without signing or submitting yet.

### Implementation

- Validate response schema, App Master authorization, request/challenge binding,
  intended device, environment, expiry, and replay state.
- Decode and independently inspect the transaction.
- Verify exact operation count, order, sources, amounts, asset/issuer, time bounds,
  fee ceiling, destination, and App Master signatures.
- Decrypt the candidate provider configuration but do not commit it.
- Return only a safe `ActivationReview` to the application.

### Implemented boundary

- Builder camera scanning and QR-image import pass opaque values directly to the
  Wallet SDK.
- The SDK validates exact schema and bounds, local request/challenge/device binding,
  timestamps, environment/version binding, authorization, replay, and device-bound
  authenticated decryption.
- It independently validates operation order, sources, destination, amounts, asset
  consistency, time bounds, fee ceiling, and the App Master signature.
- The provider candidate is validated but not committed. The feature sees only a
  plain-language review; signing and submission remain disabled.

### User test

Scan/import the response on phone A. Confirm the correct plain-language activation
review appears. Wrong-device, expired, modified, and repeated responses must fail.

### Exit condition

The Builder can safely review a real response without any signature or submission.

## Step 13 — Builder approval, signing, and direct submission

**Implementation status:** Implemented and automated checks passed on
2026-09-19. Awaiting testnet user verification.

### Goal

Implement `approveActivation()` through one direct Horizon submission.

### Implementation

- Require the exact previously inspected response ID.
- Repeat all binding and transaction checks immediately before signing.
- Add the Builder signature using the protected local credential.
- Persist transaction hash and `submitting` state before network submission.
- Submit with `POST /transactions` using form field `tx`.
- Never blindly rebuild or resubmit after a timeout or ambiguous result.
- Map definite rejection separately from uncertain submission.

### Implemented boundary

- Approval requires the exact protected response that was previously inspected.
- The SDK repeats response, device, configuration, transaction-policy, and App
  Master signature checks immediately before accessing the Builder signing key.
- It calculates and persists the transaction hash with `submitting` before adding
  the Builder signature and making one authenticated `POST /transactions` request.
- A persisted submitting/submitted/rejected/uncertain record prevents a second
  submission. Response bodies and protocol errors never reach feature code.
- Accepted submission remains pending verification; configuration commit and
  Rewards activation belong to Step 14.

### User test

Approve on phone A using testnet. Confirm only one submission occurs. Exercise a
definite rejection and an interrupted submission without exposing protocol errors.

### Exit condition

The Builder can sign and submit the approved atomic activation transaction.

## Step 14 — Reconciliation, configuration commit, and activation restoration

**Implementation status:** Implemented and automated checks passed on
2026-09-19. Awaiting interrupted-submission and restart device verification.

### Goal

Mark Rewards active only after authoritative verification.

### Implementation

- Implement `GET /transactions/{hash}` reconciliation with bounded retry.
- Verify the created account, Rewards trustline, starting Rewards balance, and
  expected transaction outcome through authoritative account reads.
- Health-check the decrypted NOWNodes candidate.
- Atomically commit provider configuration and activated state only after all
  verification succeeds.
- Retain pending/submitting state across process death.
- Implement `getActivationStatus()` and route restoration for every durable state.
- Consume replay markers only at the correct lifecycle points.

### Implemented boundary

- The SDK performs bounded direct transaction/account reads using the persisted
  transaction hash and decrypted candidate configuration.
- It verifies successful transaction state, the exact Builder account, expected
  Rewards code/issuer, and minimum starting balance.
- Only after ledger verification does it health-check and promote the provider
  configuration, then persist verified active state.
- Pending, rejected, uncertain, and active state restore without resubmission.
  Startup reconciles pending/uncertain state and routes verified activation to the
  Rewards screen.

### User test

Complete activation on two physical devices, restart the Builder app, and confirm
it restores directly to verified Rewards. Repeat with connectivity interrupted
after submission and confirm reconciliation resolves without duplicate funding.

### Exit condition

First-time activation is end-to-end functional and recoverable.

## Step 15 — Provider configuration update and rotation QR

### Goal

Change an expired or rotated NOWNodes key without reinstalling the app.

### Implementation

- Implement the five configuration-request/update facade operations.
- Use a QR type distinct from activation.
- Enforce App Master authorization, device binding, challenge, expiry, replay, and
  monotonically increasing configuration version.
- Preserve the current configuration while validating and health-checking the
  candidate.
- Promote atomically and remove the prior key only after success.
- Support an operational old/new provider-key overlap window.

### User test

Generate a settings request on phone A, create the update on phone B, and apply it
on phone A. Confirm the version increases, the key is never shown, and a failed or
older update preserves the working configuration.

### Exit condition

NOWNodes credentials can be rotated through a secure two-phone handshake.

### Implementation status

Implemented. The SDK now creates and inspects device-bound configuration requests,
creates App-Master-signed encrypted updates, validates version/expiry/replay rules,
health-checks candidates, and atomically promotes successful updates.

## Step 16 — Hardening and release gate

### Goal

Prove that the limited backend-free design is safe enough for its approved threat
model and operational constraints.

### Implementation and verification

- QR tamper, wrong-device, wrong-environment, downgrade, expiry, and replay suites.
- XDR malformed-input fuzzing and operation mutation suites.
- Provider-header and diagnostic redaction tests.
- Secure-storage failure, rollback, migration, and restoration tests.
- Timeout and duplicate-submission reconciliation tests.
- Import-boundary enforcement for `lib/app/`.
- Android and iOS permission/configuration review.
- Two physical-device testnet activation and provider rotation.
- Security review of credential import, crypto construction, transaction allow-list,
  and compromised-device limitations.
- Document provider quota, monitoring, restriction, revocation, and rotation SOP.

### Exit condition

No production/mainnet release occurs until the security review and operational SOP
are approved and all release-gate tests pass.

### Implementation status

Automated hardening is implemented: configuration QR tamper, wrong-device,
expiry, downgrade and replay coverage; existing XDR mutation, redaction, protected
storage rollback, timeout and duplicate-submission suites; and an enforced app/SDK
import boundary. Platform permissions were reviewed and the provider operations SOP
is documented in `provider-operations-sop.md`. Production remains blocked on the
two-physical-device testnet run and independent security approval.

## Recommended next action

Run the Step 16 two-physical-device testnet activation and provider-rotation gate,
then obtain the required security approval. Do not enable production/mainnet first.
