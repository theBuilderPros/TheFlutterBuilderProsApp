# Decision Log

This log records the current durable product and architecture decisions.

## 2026-09-19 - App Master distributor account uses direct secret import

### Decision

- Adopt the familiar existing-wallet import interaction used by wallets such as
  LOBSTR: the App Master types or pastes the existing Stellar secret into a masked
  Advanced field.
- The SDK validates it, derives the public account privately, and saves it in
  platform-protected storage only after live verification against the configured
  environment.
- Flutter receives only safe status and a masked public account identifier.
- Clear transient input after success or failure. Do not add QR transport, logs,
  clipboard writes, ordinary preferences, source configuration, or documentation
  containing the secret.
- Allow confirmed removal and replacement; failed verification preserves the
  previously working credential.

## 2026-09-16 - Establish theBuilderPros Identity

### Decision

Use `theBuilderPros` as the product identity across the Flutter application, platform configuration, assets, and repository.

### Result

- Dart package: `the_builder_pros`
- Android namespace and application ID: `com.thebuilderpros.thebuilderpros`
- iOS and macOS bundle ID: `com.thebuilderpros.thebuilderpros`
- Linux application ID: `com.thebuilderpros.thebuilderpros`
- Desktop binary: `the_builder_pros`
- Primary logo: `assets/images/the_builder_pros_logo.png`
- Canonical repository: `https://github.com/theBuilderPros/TheFlutterBuilderProsApp.git`

The supplied horizontal wordmark is used as provided. Derived square platform assets preserve the wordmark's aspect ratio with padding; no replacement monogram is introduced. User-facing text uses `theBuilderPros`, while the artwork retains its supplied visual casing.

Legal owner, production email and domain, store registration, release signing, and external account configuration require separate approval and must not be invented in source.

## 2026-09-17 - Use a Wallet-Only First-Release Surface

### Decision

Use Rewards Wallet as the initial and only active first-release feature, without top-level navigation.

### Result

- `Routes.wallet` is the initial route.
- Wallet activation, overview, receive, send, history, and security screens form the active UI surface.
- Profile has no active screen, controller, binding, or route.
- A future standalone Profile capability must be added explicitly within `lib/app/features/profile/`.

## 2026-09-17 - Keep Features Under `lib/app/features`

### Decision

Use `lib/app/features/` as the single feature root. Keep feature-owned widgets with their feature and organize larger screen sets by user journey with one route-level screen per implementation file.

### Result

- Wallet screens are grouped under activation, overview, receive, send, history, and security folders.
- Flow barrels and `wallet_screens.dart` contain exports only.
- Reusable Builder identity widgets live under `lib/app/features/profile/widget/`.

## 2026-09-18 - Use Wallet SDK QR Activation

### Decision

Use a mobile-to-mobile QR handshake between the Builder App and App Master App. Application code uses only a simple Wallet SDK facade, opaque QR values, safe review models, and safe outcomes. Every implementation-specific detail remains private to the SDK.

### Result

- Camera scanning and QR-image import share one SDK inspection path.
- App Master provides Overview, activation review, response QR, Advanced support information, and My Rewards.
- Advanced contains service/support information and the App Master-only NOWNodes
  configuration form required for offline provisioning.
- Protected credentials never cross between phones or enter Flutter presentation state.
- Current QR and activation behavior remains presentation-only.

## 2026-09-18 - Provision Provider Configuration Through Device-Bound QR

### Decision

Keep the application backend-free for the current design. The App Master supplies
the Builder phone's provider configuration during activation and later rotates it
through a dedicated Settings QR handshake. Provider configuration is encrypted for
one Builder device, authorized by the App Master, versioned, expiring, and handled
entirely inside the Wallet SDK.

### Result

- The NOWNodes endpoint and API key are never hard-coded, committed, bundled in
  application assets, retained in ordinary Flutter state, or placed in a plaintext
  QR. App Master Advanced may accept the key through a masked field and must pass
  it immediately to the Wallet SDK, clear the field, and retain only safe status.
- The Builder activation request carries a device-specific configuration public
  key. The activation response may carry the encrypted initial provider
  configuration for that device.
- A later configuration update uses a distinct QR type and the same device binding.
- The Wallet SDK verifies App Master authorization, intended device, environment,
  expiry, replay status, and monotonically increasing configuration version before
  applying an update.
- The SDK keeps the previous configuration until the replacement passes a health
  check, then removes the old value from protected storage.
- The App Master must keep old and new provider keys active during a rotation
  window because offline devices cannot be updated remotely.
- App Master activation is blocked until the SDK reports a saved, healthy
  NOWNodes configuration. The encrypted device-bound configuration is included in
  every activation response.
- This approach improves controlled distribution and rotation but does not make a
  credential permanently secret from the owner of a compromised mobile device.

## Recording Future Decisions

Add an entry when a decision materially changes product scope, architecture, data contracts, security boundaries, platform identity, or design rules. Record:

- date and decision
- reason
- resulting constraints or consequences
- superseding decision, when applicable

Do not use this file as an implementation status report or backlog.
