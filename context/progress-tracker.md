# Progress Tracker

Last synchronized: 2026-09-19

Current runtime facts and limitations are maintained in `current-state.md`.

## Completed

### Repository and Branding

- Renamed the project and package to theBuilderPros / `the_builder_pros`.
- Configured the Android application ID as `com.thebuilderpros.thebuilderpros`.
- Configured the canonical repository and `main` branch.
- Added the official source logo.
- Replaced Android launcher icons and the web favicon.
- Updated repository documentation for the mobile product.

### UI Prototype

- Added the presentation-only Rewards wallet flow under `lib/app/features/wallet/` from the wallet sub-feature screen specification.
- Refactored Builder identity into a reusable shared card used by the Rewards activation entry screen.
- Added mock screens for activation, authentication, wallet overview, receive, send scan/amount/review/outcome, history, locked state, and wallet removal.
- Added an App Master feature with activation capacity, Rewards availability, Builder access, activation-request scan/image-import actions, activation review, and activation-QR preview.
- Removed provider-specific terminology from Builder-facing and ordinary App Master UI. NOWNodes configuration is the sole App Master Advanced exception; its prototype form clears the key after save while real validation, protected persistence, and QR provisioning remain Wallet SDK work.
- Added explicit switching between the App Master and shared Builder Rewards surfaces for testing both roles.
- Split route-level Wallet screens into one implementation file per screen, grouped by user journey with export-only barrels.
- Centralized reusable Wallet presentation components under the Wallet feature.

### Functional Wallet SDK Slice

- Added the public `WalletSdk` facade with safe Builder and activation-request models.
- Implemented Start activation with validation, duplicate-tap prevention, safe progress, and safe failures.
- Added protected local setup, persisted 15-minute pending requests, restoration, cancellation, and rollback behavior behind the SDK.
- Replaced the mock request icon and ID with a real generated QR, request ID, expiry, and exact copy action.
- Added production SDK lifecycle tests and injected a fake SDK into widget tests.
- Replaced `stellar_flutter_sdk` with generic Ed25519 key generation and a private
  SEP-23 StrKey codec.
- Split activation QR encoding, protected credentials, pending-request persistence,
  time, and token generation into private SDK services.
- Added official-vector, invalid-input, deterministic key derivation, expiry cleanup,
  and persistence-rollback tests.
- Added safe provider-configuration facade models, strict NOWNodes candidate
  validation, protected pending storage, safe status restoration, explicit clearing,
  and transactional rollback when safe metadata persistence fails.
- Wired confirmed Builder activation cancellation to SDK cleanup and added safe,
  retryable failure behavior.
- Made `WalletController` application-scoped to prevent disposed text controllers
  from being reused during wallet route replacement on physical devices.
- Added a private direct Horizon HTTP health client with NOWNodes header injection,
  network-identity checks, bounded response parsing, safe failure mapping, total and
  phase deadlines, and bounded transient retry with jitter.
- Added atomic pending-to-active configuration promotion and verified that failed
  replacement health checks preserve the previous working configuration.
- Connected App Master Advanced to the public provider-configuration facade with
  environment selection, duplicate-submit protection, transient key clearing, safe
  error display, and restoration of non-secret status metadata.
- Added widget coverage proving successful configuration and rejected-key paths do
  not retain or render the submitted key.
- Reproduced the live NOWNodes response, added Horizon HAL JSON compatibility, and
  kept its credential-bearing link payload confined to the private transport layer.
- Removed the temporarily documented live API key; it must be rotated before reuse.
- Added a protected, installation-stable X25519 device-configuration identity that
  is separate from the Builder activation signing identity.
- Upgraded activation requests to a canonical, bounded v2 envelope containing only
  the opaque device ID and configuration public key, with strict restore validation
  and legacy-v1 invalidation.
- Added tests for deterministic encoding, malformed/oversized/unsupported/expired/
  altered rejection, stable device binding, private-key exclusion, and v1 cleanup.
- Added real App Master QR camera scanning and gallery-image decoding behind a
  focused adapter, including exact-value forwarding and safe cancel, denied,
  unreadable, and multiple-code outcomes.
- Declared purpose-specific Android and iOS camera/photo permissions and added
  adapter plus widget coverage for the Step 6 acquisition paths.
- Added SDK-backed App Master request inspection, consumed-request checks,
  protected pending-review restoration, and safe public review models.
- Replaced mock App Master review identity with validated Builder name, phone,
  request ID, expiry, and plain-language setup rows.
- Added App Master direct distributor-secret import with masked entry, explicit
  confirmation, private key derivation, live account verification, protected
  storage, safe masked status, replacement safety, and confirmed removal.
- Added authenticated direct account and fee-status reads, private ledger parsing,
  and a safe App Master overview facade for live capacity, Rewards availability,
  service status, and refresh behavior.
- Added the version-pinned Stellar XDR v27 activation subset, committed generator,
  strict RFC 4506 codec, limited classic-envelope round trips, transaction hashing,
  Ed25519 signing/verification, signature preservation, and fail-closed rejection
  of every unsupported protocol variant.
- Added SDK-backed App Master activation approval with live sequence and fee policy,
  exact three-operation construction, protected distributor signing, device-bound
  provider encryption, response authorization, and real QR rendering.
- Added Builder response camera/gallery acquisition, device-bound decryption,
  response and transaction authorization checks, exact policy inspection, replay
  rejection, protected pending-response storage, and safe review UI.
- Added exact-response Builder approval, repeat policy validation, protected local
  signing, pre-submit hash/state persistence, single direct transaction submission,
  duplicate prevention, and safe submitted/rejected/uncertain outcomes.
- Added direct transaction/account reconciliation, expected Builder Rewards-state
  verification, provider candidate health-check/promotion, durable active state,
  and startup restoration without duplicate submission.

### Design System

- Applied neutral backgrounds and white surfaces.
- Centralized core theme colors and Material component themes.
- Applied orange primary actions and restrained violet selection states.
- Added the mixed orange/violet page-title underline.

### Verification Record

- `flutter analyze` passed on 2026-09-18.
- `flutter test` passed all 27 Step 4 SDK, protocol, transport, lifecycle, and widget
  tests on 2026-09-18.
- `flutter analyze`, all 32 Step 5 tests, and `flutter build apk --debug` passed on
  2026-09-19.
- `flutter analyze`, all 38 Step 6 tests, and `flutter build apk --debug` passed on
  2026-09-19.
- `flutter analyze`, all 43 Step 7 tests, and `flutter build apk --debug` passed on
  2026-09-19.
- `flutter analyze`, all 47 Step 8 tests, and `flutter build apk --debug` passed on
  2026-09-19.
- `flutter analyze`, all 49 Step 9 tests, and `flutter build apk --debug` passed on
  2026-09-19.
- The Step 10 generator reproduced its checked-in constants; `flutter analyze` and
  all 58 tests passed on 2026-09-19. No native build input changed.
- `flutter analyze` and all 60 Step 11 tests passed on 2026-09-19. No native build
  input changed.
- `flutter analyze` and all 60 Step 12 tests passed on 2026-09-19. No native build
  input changed.
- `flutter analyze` and all 63 Step 13 tests passed on 2026-09-19. No native build
  input changed.
- `flutter analyze` and all 64 Step 14 tests passed on 2026-09-19. No native build
  input changed.
- `flutter analyze` and all 64 Step 15 tests passed on 2026-09-19. No native build
  input changed.
- `flutter analyze` and all 67 Step 16 automated tests passed on 2026-09-19.
- `flutter build apk --debug` produced `build/app/outputs/flutter-apk/app-debug.apk` on 2026-09-18.

These entries record completed checks at that point in history. They do not replace verification after later changes.

## Active Backlog

The gated implementation order is maintained in
`docs/walletsub-feature01/stepbystep.md`. Steps 1 through 9 are complete and device
verified. Steps 10-16 are implemented and pass automated checks. The two-physical-
device testnet run and independent security approval remain release gates.

1. Complete Wallet SDK Steps 1-16 with user verification between steps.
2. Add loading, empty, offline, and unauthenticated states to remaining flows.
3. Add integration tests on physical devices.
4. Add a standalone Profile screen, controller, binding, and route only when that feature returns to scope.

Backlog order may change through an explicit planning decision. Architectural direction belongs in `architecture.md`; capability claims belong in `current-state.md`.
