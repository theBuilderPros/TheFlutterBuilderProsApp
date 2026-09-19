# Current State

Last synchronized: 2026-09-19

## Repository

- Primary branch: `main`
- Canonical repository: `https://github.com/theBuilderPros/TheFlutterBuilderProsApp.git`
- Dart package: `the_builder_pros`
- Android application ID: `com.thebuilderpros.thebuilderpros`
- Product name: `theBuilderPros`

## Runtime

The app currently runs as a Flutter Material 3 application using GetX for routing, dependency injection, and reactive state.

The initial route opens the wallet-owned not-activated Rewards screen. Start activation is the first functional Wallet SDK slice; the remaining Builder Rewards and App Master flows are presentation prototypes exposed through explicit role-switch controls.

The Builder Rewards flow lives under `lib/app/features/wallet/`. Its not-activated action calls the public `WalletSdk`, creates protected local activation state, persists a 15-minute pending request, and renders a real QR from the opaque SDK value. Activation response review, Rewards overview, receive, send, history, security, and the App Master feature remain presentation-only. The production SDK facade lives under `lib/wallet_sdk/`; feature code imports only its safe public API.

The first SDK slice no longer depends on `stellar_flutter_sdk`. Private services now
own generic Ed25519 key generation, SEP-23 StrKey encoding/validation, activation QR
encoding, secure credentials, pending activation persistence, time, and token
generation.

Step 1 has passed user device testing. The Activation Request screen now exposes a
confirmed Cancel activation action that calls the SDK, clears the request and
protected credential, and returns to the not-activated screen. Cleanup failure keeps
the request available and shows a safe retryable message.

The SDK accepts strictly validated NOWNodes configuration input and health-checks it
through a private direct Horizon HTTP client. The client injects `api-key` only at
the transport boundary, enforces HTTPS/origin policy, connection/read/total
deadlines and response-size/content checks, validates network identity, and maps
provider failures to safe codes. Rate limits, timeouts, and transient service
failures use bounded retry with jitter. A healthy candidate is promoted atomically;
failure removes it and preserves the previous active configuration. App Master
Advanced now submits endpoint, environment, and the transiently entered key through
the public `WalletSdk`; it prevents duplicate saves, clears the field after success
or failure, and restores only safe readiness/version/check-time metadata.

A live NOWNodes check on 2026-09-19 confirmed that its Horizon root uses
`application/hal+json` and includes the credential in returned HAL link URLs. The
SDK now accepts that JSON media type but never exposes or logs the response body or
links. The key temporarily placed in `stepbystep.md` was removed and must be rotated.

`WalletController` is application-scoped because it owns text controllers shared
across wallet routes. This prevents GetX route replacement from disposing those
controllers while a replacement wallet screen is being built.

## Implemented Presentation Behavior

- Validate Builder name and phone, prevent duplicate activation taps, and show safe loading/failure states.
- Generate and restore a protected local activation request through `WalletSdk`, render its real QR, show its request ID/expiry, and copy the opaque SDK value.
- Switch to App Master, inspect activation capacity, Rewards availability, and Builder access, scan or import an activation request, review the activation package, and display/save a mock activation QR.
- Open App Master Advanced to enter a masked NOWNodes key, select its environment,
  health-check and protect the configuration through `WalletSdk`, and inspect only
  safe readiness, version, and last-check information.
- Navigate Receive, Send scan, amount, review, outcome, history, locked-wallet, and removal presentations.
- Preview successful, rejected, and pending send outcomes.

## Current Limitations

Pending activation-request state is persisted locally. Other records and interaction state remain in memory. The app currently has no:

- authentication or user session
- backend client
- real Rewards balance, history, transfer, custody, or signing
- completed App Master request inspection after QR acquisition
- working notification action
- loading, network, offline, or unauthenticated states
- production-grade form submission or identity/phone verification
- Builder-side activation response inspection, approval, submission, reconciliation,
  or Rewards service operations

The Profile feature contains the reusable Builder identity card used by activation. Automated coverage includes the Wallet SDK request lifecycle, startup, Builder activation navigation, and App Master activation-package navigation.

## Branding Assets

- Source logo: `assets/images/the_builder_pros_logo.png`
- Android launcher icons: branded density-specific PNGs
- Web favicon: branded PNG

Platform configuration contains the theBuilderPros identity described in the latest decision log entry.

## Verification Record

The Step 4 App Master provider-configuration integration passed automated checks on
2026-09-18:

- `flutter analyze`
- `flutter test`
- `flutter build apk --debug`

Step 4 was subsequently confirmed working on a physical device.

Step 5 now creates a separate X25519 device-configuration identity in protected
storage. Activation request v2 exposes only its opaque device ID and public key,
uses a bounded canonical envelope with an alteration checksum, and is strictly
validated during restore. Legacy v1 pending requests are invalidated and their
activation credentials removed. Step 5 automated checks pass; its physical-device
create/restore/second-phone QR check passed on 2026-09-19.

The Step 5 verification record on 2026-09-19 is `flutter analyze`, all 32 tests,
and `flutter build apk --debug` passing.

Step 6, device verified on 2026-09-19, adds real App Master camera scanning and
QR-image selection behind a focused
adapter. It forwards the decoded value byte-for-byte, rejects multiple distinct
codes, and distinguishes cancellation, unreadable input, and camera denial with
safe UI states. Camera/photo access is requested only by the related action. The
opaque value is retained transiently for the Step 7 SDK inspection call; request
schema parsing remains absent from widgets and controllers.

Step 7 now sends the opaque value to `WalletSdk.inspectBuilderRequest()`. The SDK
strictly validates the request, checks its consumed-request store, protects the
pending raw request for restoration, and returns a safe review containing only the
Builder identity, request ID, expiry, and plain-language setup steps. The App Master
review screen no longer contains mock Builder details.

The Step 7 verification record on 2026-09-19 is `flutter analyze`, all 43 tests,
and `flutter build apk --debug` passing.

Step 7 was subsequently confirmed working on a physical device. Step 8 now uses an
approved LOBSTR-style direct import in App Master Advanced. The SDK validates the
Stellar secret, derives the account, verifies it through the protected active
provider configuration, saves only after success, restores masked status, supports
confirmed removal, and keeps failed replacements from overwriting the prior secret.

The Step 8 verification record on 2026-09-19 is `flutter analyze`, all 47 tests,
and `flutter build apk --debug` passing. Step 8 was subsequently device verified.

Step 9 now loads the protected distributor account and fee state directly from
Horizon, parses balances, liabilities, subentries, sequence, trustlines, and fee
percentiles privately, and exposes only estimated activation capacity, safe Rewards
availability, service status, and refresh time. App Master Overview and Advanced no
longer use mock capacity or Rewards totals.

Capacity is currently a conservative estimate using a private 0.5 base-reserve
assumption, retained safety margin, current subentry count/liabilities, three p95
fees, and 2.1 units of activation funding per Builder. Until the Rewards asset code
and issuer are configured, a numeric Rewards amount is shown only when exactly one
non-native balance exists; otherwise the safe result is `Not available` or `Needs
review`.

The Step 9 verification record on 2026-09-19 is `flutter analyze`, all 49 tests,
and `flutter build apk --debug` passing.

Step 9 was subsequently confirmed working on a physical device. Step 10 now adds a
private, fail-closed Stellar classic-transaction protocol core without a Stellar
SDK. It is pinned to official Stellar XDR `v27.0` commit
`68fa1ac55692f68ad2a2ca549d0a283273554439`, with a committed activation-subset
schema, deterministic generator, and generated constants.

The Step 10 boundary implements RFC 4506 primitives and canonical padding, classic
V1 envelopes, Ed25519 accounts, optional time bounds, no memo, extension v0,
alpha-num-4/12 credit assets, and only `createAccount`, `changeTrust`, and `payment`.
It performs network-passphrase transaction hashing, Ed25519 signing and verification,
signature hints, and signature preservation. Unsupported envelope, account, asset,
memo, precondition, extension, or operation variants are rejected. This layer is
not yet connected to App Master approval or live submission.

The Step 10 verification record on 2026-09-19 is deterministic generator execution,
`flutter analyze`, and all 58 tests passing. No native dependency or platform
configuration changed, so this step does not require a replacement Android build.

Step 11 connects App Master approval to live account and fee reads, the limited
protocol core, protected distributor signing, device-bound provider-configuration
encryption, complete-response authorization, and a real activation QR. The request
remains pending and is not consumed. Builder response inspection, local approval,
submission, and reconciliation remain Steps 12-14.

The Step 11 verification record on 2026-09-19 is `flutter analyze` and all 60
tests passing. No native build input changed.

Step 12 adds Builder camera/gallery response acquisition and SDK-only inspection.
It validates authorization, local request/device binding, expiry/replay,
authenticated provider decryption, exact transaction policy, and the App Master
signature. It stores the verified opaque response for Step 13 but does not commit
configuration, sign, submit, or mark Rewards active.

The Step 12 verification record on 2026-09-19 is `flutter analyze` and all 60
tests passing. No native build input changed.

Step 13 revalidates the protected inspected response, signs the exact transaction
with the protected Builder key, persists its hash and submitting state first, and
makes one direct authenticated Horizon submission. Durable state prevents blind
resubmission and distinguishes accepted, definite rejection, and uncertain results.
Accepted still means pending Step 14 authoritative verification.

The Step 13 verification record on 2026-09-19 is `flutter analyze` and all 63
tests passing. No native build input changed.

Step 14 adds bounded direct transaction/account reconciliation, verifies the exact
Builder account and starting Rewards balance, health-checks and promotes the
device-bound provider candidate, and persists active state. Startup restores and
reconciles pending/uncertain state without resubmission, routing verified activation
to Rewards.

The Step 14 verification record on 2026-09-19 is `flutter analyze` and all 64
tests passing. No native build input changed.

Step 15 adds distinct configuration request/update QR payloads, device-bound
authenticated encryption, App Master authorization, expiry/replay/downgrade
checks, candidate health validation, and atomic configuration promotion.

The Step 15 verification record on 2026-09-19 is `flutter analyze` and all 64
tests passing. No native build input changed.

Step 16 adds configuration-handshake abuse coverage, SDK import-boundary
enforcement, reviewed mobile QR permissions, and the provider operations SOP. The
existing suites cover XDR mutation, redaction, protected-storage rollback,
submission timeout, and duplicate prevention. Production remains blocked pending
the two-device testnet gate and independent security approval.

The Step 16 automated verification record on 2026-09-19 is `flutter analyze` and
all 67 tests passing.

The Step 6 verification record on 2026-09-19 is `flutter analyze`, all 38 tests,
and `flutter build apk --debug` passing. Android disables Kotlin incremental
compilation because Flutter plugin sources and the project occupy different Windows
drive roots, which otherwise corrupts Kotlin's relative-path cache.

See `progress-tracker.md` for completed work and the active backlog.
