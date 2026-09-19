# Wallet SDK Specification

## 1. Purpose

`WalletSdk` is the only Rewards integration boundary visible to Flutter features.
It exposes simple product operations and safe view models. All Stellar protocol,
cryptography, XDR, Horizon HTTP, provider authentication, secure storage,
validation, signing, retry, and reconciliation details are private SDK internals.

The SDK must call Stellar-compatible HTTP APIs directly. It must not depend on
`stellar_flutter_sdk` or another full Stellar SDK.

## 2. Reference implementation finding

The reference wallet uses `stellar_flutter_sdk: ^2.2.2` for local Stellar objects
and uses direct HTTP calls for Horizon access. Its configuration contains:

```json
{
  "horizonUrl": "https://xlm.nownodes.io",
  "nownodeApiKey": "YOUR_NOWNODES_API_KEY"
}
```

The reference services send the value in an `api-key` header when loading accounts,
loading balances, validating recipients, and submitting transactions.

The new SDK must not copy the reference asset-based key pattern. A key bundled in a
mobile application is recoverable and cannot be treated as a secret.

## 3. Provider policy

The SDK supports a configurable Horizon-compatible base URL and optional request
headers:

```dart
final class WalletSdkEnvironment {
  const WalletSdkEnvironment({
    required this.id,
    required this.horizonBaseUrl,
    required this.networkPassphrase,
    this.providerHeaders = const <String, String>{},
  });

  final String id;
  final Uri horizonBaseUrl;
  final String networkPassphrase;
  final Map<String, String> providerHeaders;
}
```

Rules:

- Development may use the public Stellar test endpoint without an API key.
- Production endpoint selection is a release decision.
- Provider headers remain optional in the reusable Wallet SDK transport contract so
  development can use a public test endpoint. This product's production activation
  policy requires a healthy saved NOWNodes configuration before App Master approval.
- No provider key may be committed, bundled in assets, hard-coded, logged, placed
  in analytics, or placed in a plaintext QR artifact.
- The App Master provisions the initial provider configuration through the
  device-bound activation response and rotates it through the Settings QR flow.
- Configuration QR ciphertext is unique to the intended Builder device. A global
  QR containing a shared plaintext key is forbidden.
- The configuration is stored with platform-backed secure storage after validation.
  It must still be considered extractable from a compromised device and restricted
  at the provider where possible.
- Provider headers are injected only inside the private HTTP adapter.

## 4. Public application interface

```dart
abstract interface class WalletSdk {
  Future<ActivationRequestView> startActivation(BuilderIdentity builder);
  Future<ActivationRequestView?> restoreActivationRequest();
  Future<ActivationRequestReview> inspectBuilderRequest(String qrValue);
  Future<ActivationResponseView> approveBuilderRequest(String requestId);
  Future<ActivationReview> inspectActivationResponse(String qrValue);
  Future<ActivationOutcome> approveActivation(String responseId);
  Future<ActivationStatus> getActivationStatus();
  Future<void> cancelActivation();
  Future<ConfigurationRequestView> createConfigurationRequest();
  Future<ConfigurationRequestReview> inspectConfigurationRequest(String qrValue);
  Future<ConfigurationUpdateView> createConfigurationUpdate(String requestId);
  Future<ConfigurationReview> inspectConfigurationUpdate(String qrValue);
  Future<ConfigurationOutcome> applyConfigurationUpdate(String updateId);
  Future<ProviderConfigurationOutcome> saveAppMasterProviderConfiguration(
    ProviderConfigurationInput input,
  );
  Future<ProviderConfigurationStatus> getProviderConfigurationStatus();
}
```

Application-facing objects contain only display-ready product data, stable IDs,
opaque QR strings, expiry, safe status enums, retry flags, and support references.
They never expose Stellar addresses, seeds, XDR, signatures, sequence numbers,
fees, operation names, Horizon records, or provider response bodies.

`ProviderConfigurationInput` is the sole exception for App Master setup. It accepts
the endpoint, masked-field API-key value, environment, and next configuration
version. The controller passes it directly to the SDK and immediately clears the
field. The SDK returns only a safe status; it never returns the API key.

## 5. Private SDK modules

```text
wallet_sdk/
|-- wallet_sdk.dart                    public facade and safe models
`-- src/
    |-- default_wallet_sdk.dart        use-case orchestration
    |-- configuration/
    |   |-- configuration_handshake_service.dart
    |   |-- configuration_policy.dart
    |   |-- provider_configuration.dart
    |   `-- wallet_sdk_environment.dart
    |-- activation/
    |   |-- activation_request_service.dart
    |   |-- activation_response_service.dart
    |   |-- activation_policy.dart
    |   `-- activation_reconciler.dart
    |-- protocol/
    |   |-- strkey_codec.dart
    |   |-- xdr_reader.dart
    |   |-- xdr_writer.dart
    |   |-- transaction_builder.dart
    |   |-- transaction_inspector.dart
    |   `-- signature_service.dart
    |-- transport/
    |   |-- horizon_client.dart
    |   |-- horizon_models.dart
    |   |-- provider_header_policy.dart
    |   `-- retry_policy.dart
    |-- qr/
    |   |-- activation_qr_codec.dart
    |   |-- configuration_qr_codec.dart
    |   `-- qr_integrity_service.dart
    |-- storage/
    |   |-- credential_store.dart
    |   |-- activation_store.dart
    |   |-- configuration_store.dart
    |   `-- replay_store.dart
    `-- diagnostics/
        |-- sdk_event.dart
        `-- sdk_diagnostics.dart
```

No file under `lib/app/` may import `wallet_sdk/src/`. Only the application
composition root may construct the private implementation.

## 6. Direct Stellar HTTP surface

The classic Rewards workflow uses Horizon-compatible HTTP endpoints directly:

| Purpose | HTTP request | SDK use |
| --- | --- | --- |
| Server health/network identity | `GET /` | Validate configured environment before sensitive work |
| Load account and sequence | `GET /accounts/{account_id}` | Build from current authoritative state |
| Read balances and trustlines | `GET /accounts/{account_id}` | Capacity, eligibility, and post-submit verification |
| Estimate fee | `GET /fee_stats` | Apply approved fee policy and cap |
| Submit envelope | `POST /transactions` | Send form field `tx=<base64 envelope>` |
| Reconcile result | `GET /transactions/{hash}` | Resolve timeout or interrupted submission |

HTTP rules:

- HTTPS only outside local test environments.
- Normalize the base URL once and prevent path/host injection.
- Apply connection, read, and total deadlines.
- Cap response size before JSON decoding.
- Require expected content types.
- Parse into private typed DTOs; never return raw JSON to the application.
- Redact headers, URLs with credentials, envelope bodies, and provider payloads.
- Treat `404` according to endpoint context rather than as a generic failure.
- On `429` or transient `5xx`, use bounded backoff with jitter.
- Never rebuild and resubmit after an ambiguous result until reconciliation proves
  it is safe.

## 7. Protocol implementation without a Stellar SDK

The private protocol layer must implement and test:

### Key and address handling

- secure Ed25519 seed generation using the operating system random source;
- Ed25519 public-key derivation and signing through a reviewed generic crypto
  library or platform primitive;
- Stellar StrKey version bytes, Base32 encoding/decoding, and CRC16-XModem checksum;
- constant-time comparison where protected values are compared;
- zeroization where supported by the language/runtime.

### XDR

- RFC 4506 big-endian primitives and 4-byte padding;
- the exact Stellar protocol structures required by this product;
- strict discriminant, length, and bounds validation;
- canonical encoding and byte-for-byte round-trip fixtures;
- rejection of unknown or unsupported operations in activation responses.

Do not hand-maintain protocol definitions from memory. Generate or derive codecs
from the version-pinned official Stellar `.x` definitions, commit the generator and
generated source, and record the supported protocol version. A protocol upgrade is
an explicit SDK release.

The implemented activation subset is pinned to official Stellar XDR `v27.0`, exact
commit `68fa1ac55692f68ad2a2ca549d0a283273554439`. Its committed schema and generator
produce the discriminants and bounds used by the private codec. The codec accepts
only classic V1 envelopes, Ed25519 accounts, no memo, no or time-bound
preconditions, extension v0, credit alpha-num-4/12 assets, and the three activation
operations. It rejects all other protocol variants rather than partially decoding
them.

### Transaction hashing and signatures

- derive the network ID from SHA-256 of the configured passphrase;
- construct the signature base from the network ID, envelope type, and transaction
  XDR;
- hash the signature base with SHA-256;
- create and verify Ed25519 signatures;
- derive and validate signature hints;
- preserve existing valid signatures when adding the local signature;
- reject duplicate, unexpected, missing, or invalid signatures.

## 8. Activation transaction contract

The App Master SDK constructs one classic atomic transaction with:

1. `createAccount`, sourced by the App Master-controlled distributor;
2. `changeTrust`, sourced by the new Builder account; and
3. `payment`, sourced by the distributor, delivering starting Rewards.

Before returning a response QR, the SDK validates:

- network and environment;
- current distributor sequence;
- time bounds and fee ceiling;
- exact Builder address from the request;
- configured Rewards code and issuer;
- approved starting XLM and Rewards amounts;
- operation count, order, source accounts, and absence of extra operations; and
- all App Master-controlled signatures.

The Builder SDK independently decodes the response and repeats the full allow-list
validation. It signs only after the application calls `approveActivation()` for
the inspected response ID.

## 9. QR schemas

QR values are opaque to Flutter code but versioned inside the SDK.

### Request

```json
{
  "payload": {
    "type": "rewards_activation_request",
    "version": 2,
    "request_id": "...",
    "challenge": "...",
    "created_at": "...",
    "expires_at": "...",
    "environment": "test",
    "builder": {"name": "...", "phone": "..."},
    "activation_address": "G...",
    "device_id": "...",
    "device_configuration_public_key": "..."
  },
  "integrity": "..."
}
```

The v2 request encoder uses a fixed field order and a SHA-256 integrity checksum
over the canonical payload. This detects accidental or un-recomputed alteration;
it is not App Master authentication. App Master authorization is provided by the
signed response protocol. The decoder enforces exact fields, types, version, byte
limit, device-key lengths, timestamps, lifetime, and checksum before returning a
private decoded model.

### Response

```json
{
  "type": "rewards_activation_response",
  "version": 1,
  "response_id": "...",
  "request_id": "...",
  "challenge": "...",
  "expires_at": "...",
  "environment": "...",
  "activation_address": "G...",
  "envelope_xdr": "...",
  "encrypted_provider_configuration": {
    "algorithm": "X25519-HKDF-SHA256-XCHACHA20POLY1305",
    "ephemeral_public_key": "...",
    "nonce": "...",
    "ciphertext": "..."
  },
  "app_master_key_id": "...",
  "integrity_signature": "..."
}
```

Enforce byte-size limits before parsing. Canonicalize the integrity-signature input.
If a response does not fit the selected static QR error-correction level, fail
closed until an approved animated-QR or compression profile exists.

## 10. Provider configuration QR handshake

### 10.1 Trust and device binding

The Wallet SDK creates a separate device configuration encryption identity. Use an
X25519 key agreement identity for configuration encryption; do not treat the
Builder's Ed25519 activation identity as an encryption key.

The Builder configuration private key remains in platform-backed secure storage.
The corresponding public key and an opaque device ID may appear in activation and
configuration-request QR artifacts.

The Builder SDK must have an approved App Master verification trust root before it
accepts a configuration. The trust root is public verification material, not the
App Master's private credential. Its provisioning and rotation must be separately
versioned and security-reviewed.

### 10.2 Initial configuration during activation

0. App Master enters the NOWNodes endpoint and API key in Advanced. The controller
   passes it directly to `saveAppMasterProviderConfiguration()`, clears the field,
   and renders only the returned safe status. The SDK validates the endpoint,
   performs a health check, and saves the configuration in protected storage.
1. Builder SDK includes its configuration public key and device ID in the
   activation request.
2. App Master SDK validates the activation request.
3. App Master selects the approved provider configuration from its protected
   storage.
4. App Master SDK encrypts that configuration uniquely for the Builder device.
5. App Master SDK binds the ciphertext to the activation request, device,
   environment, configuration version, issue time, and expiry.
6. App Master SDK authorizes the complete response.
7. Builder SDK validates authorization and binding before decryption.
8. Builder SDK decrypts and validates the provider configuration internally.
9. Builder SDK performs a provider health check.
10. Builder SDK saves the configuration in protected storage only after the health
    check succeeds.

`approveBuilderRequest()` must fail with `providerConfigurationRequired` when no
healthy App Master configuration is installed. Every activation response includes
the encrypted configuration and its monotonically increasing version.

### 10.3 Settings update handshake

Configuration rotation uses `wallet_configuration_request` and
`wallet_configuration_update`; it never reuses activation or Rewards-transfer QR
types.

The Builder can show a fresh configuration-request QR, or the App Master may use a
previously stored device public key after selecting the exact Builder. The fresh
request is preferred because it supplies a new challenge and proves the device is
present.

```text
Builder Settings -> createConfigurationRequest()
App Master -> inspectConfigurationRequest(qrValue)
App Master -> createConfigurationUpdate(requestId)
Builder Settings -> inspectConfigurationUpdate(qrValue)
Builder confirms safe provider/environment summary
Builder Settings -> applyConfigurationUpdate(updateId)
```

### 10.4 Configuration request schema

```json
{
  "type": "wallet_configuration_request",
  "version": 1,
  "request_id": "...",
  "device_id": "...",
  "device_configuration_public_key": "...",
  "current_configuration_version": 3,
  "environment": "production",
  "challenge": "...",
  "created_at": "...",
  "expires_at": "..."
}
```

### 10.5 Configuration update schema

```json
{
  "type": "wallet_configuration_update",
  "version": 1,
  "update_id": "...",
  "request_id": "...",
  "device_id": "...",
  "environment": "production",
  "configuration_version": 4,
  "issued_at": "...",
  "expires_at": "...",
  "encrypted_configuration": {
    "algorithm": "X25519-HKDF-SHA256-XCHACHA20POLY1305",
    "ephemeral_public_key": "...",
    "nonce": "...",
    "ciphertext": "..."
  },
  "app_master_key_id": "...",
  "integrity_signature": "..."
}
```

The encrypted plaintext contains only the approved endpoint, required provider
headers, configuration version, environment, and health-check policy. It must not
contain App Master account credentials.

### 10.6 Update validation and commit

Before decryption or application, validate:

- QR type and schema version;
- App Master authorization against the trusted verification root;
- request ID, fresh challenge, intended device ID, and device key binding;
- expected environment;
- issue and expiry times;
- replay status; and
- configuration version strictly greater than the installed version.

Apply the update transactionally:

1. retain the current configuration;
2. decrypt the candidate inside the SDK;
3. validate endpoint allow-list, HTTPS, header names, and value sizes;
4. save the candidate as pending in protected storage;
5. perform a bounded provider health check;
6. promote the candidate atomically when healthy;
7. delete the previous configuration after promotion; and
8. record the update ID and version as consumed.

If any step fails, preserve the previous working configuration and return a safe
failure. Never fall back to a bundled key.

### 10.7 Rotation operations

- App Master creates a new provider key and configuration version.
- Old and new keys remain valid during a defined overlap window.
- Each Builder device receives and applies its device-bound update QR.
- Without a backend, App Master cannot remotely prove every offline device updated.
- An optional Builder-generated confirmation QR may let the App Master mark a
  device as updated in its local roster.
- Revoke the old provider key only after the operational migration policy is met.

This QR design provides offline distribution and rotation, not absolute secrecy on
a compromised device. Provider quotas, monitoring, restriction, and revocation
remain required.

## 11. Storage model

### Platform-backed secure storage

- Builder secret seed;
- App Master distributor secret seed;
- optional provider API key;
- device configuration private key;
- installed and pending provider configurations;
- integrity/trust-root material that is not public; and
- protected authentication state.

### Ordinary local persistence

- request and response IDs;
- opaque QR values when required for restoration;
- expiry and safe workflow status;
- safe Builder display data;
- transaction hash for reconciliation; and
- replay markers.

Never store secret seeds, provider keys, decoded protected QR internals, or signed
envelopes in ordinary preferences, controller state, analytics, or crash reports.

## 12. Error mapping

Private failures map to stable public codes such as:

- `invalidBuilder`
- `invalidQr`
- `expiredQr`
- `wrongEnvironment`
- `requestMismatch`
- `requestAlreadyUsed`
- `activationCapacityUnavailable`
- `approvalRejected`
- `serviceUnavailable`
- `verificationPending`
- `verificationFailed`
- `restartRequired`
- `configurationNotNewer`
- `configurationNotForDevice`
- `configurationHealthCheckFailed`
- `providerConfigurationRequired`

The public error includes only `code`, `safeMessage`, `canRetry`, and an optional
support reference. Raw Horizon result codes and response bodies remain private.

## 13. Testing requirements

- official StrKey valid/invalid vectors;
- CRC and Base32 property tests;
- official XDR fixtures and byte-for-byte round trips;
- malformed/truncated/oversized XDR fuzz tests;
- deterministic transaction and signature vectors;
- operation allow-list mutation tests;
- QR canonicalization, tampering, expiry, mismatch, and replay tests;
- HTTP contract tests for every endpoint and status class;
- timeout and duplicate-submission reconciliation tests;
- provider-header redaction tests;
- device-bound configuration encryption/decryption vectors;
- wrong-device, wrong-challenge, downgrade, expiry, tamper, and replay tests;
- health-check failure preserving the previous configuration;
- successful atomic configuration promotion and old-value removal;
- secure-storage rollback and restoration tests;
- testnet activation across two physical devices; and
- an import-boundary test proving `lib/app/` does not import private SDK files.

## 14. Current implementation gap

The first activation slice now uses private generic Ed25519 key generation and a
local SEP-23 StrKey codec. `stellar_flutter_sdk` has been removed. Request QR
encoding, protected credential access, pending activation persistence, clock, and
token generation are separated private services. Provider configuration facade
models, strict NOWNodes candidate validation, protected pending storage, safe status
restoration, explicit clearing, and failed-write rollback are implemented. The
private direct Horizon HTTP client now injects the `api-key` header, enforces
timeouts and response limits, validates the Horizon network identity, retries
bounded transient failures with jitter, and promotes a candidate atomically only
after a successful check. It accepts standard JSON media types, including the
`application/hal+json` returned by the live NOWNodes Horizon root endpoint, while
keeping the response body and its credential-bearing HAL links private. App Master
Advanced now calls the public facade, prevents
duplicate submissions, clears the entered key after every result, and restores only
safe status metadata. Step 4 is device verified. Device-bound activation request
version 2 is implemented with a separate protected X25519 installation identity,
strict private codec, stable restore binding, and safe v1 invalidation. Step 5 is
device verified. Step 6 camera and gallery QR acquisition are implemented behind
a focused adapter that forwards exact opaque values and keeps protocol parsing out
of feature code and is device verified. Step 7 SDK-backed inspection now strictly
validates request v2, rejects consumed requests, protects the pending raw request,
supports safe restoration, and exposes only Builder identity, request ID, expiry,
and plain-language setup steps; Step 7 is device verified. Step 8 uses approved
LOBSTR-style direct distributor-secret import in App Master Advanced. The private
SDK validates the StrKey, derives the Ed25519 public account, verifies it through
the active provider configuration, stores it only after success, and exposes only
masked status and is device verified.

Steps 8 and 9 are device verified. Step 9 reads the protected distributor account and
fee status directly through authenticated Horizon HTTP calls. Private DTOs retain
balances, liabilities, subentries, sequence, trustlines, and fee percentiles; the
public facade exposes only estimated activation capacity, safe Rewards availability,
service status, and refresh time.

The current estimate retains `(2 + subentry_count) * 0.5`, native selling
liabilities, three p95 fees, and a 0.5 safety margin, then divides spendable funding
by the temporary 2.1-per-Builder activation policy. These are explicit interim
policy constants, not live protocol reserve discovery. Until an allowlisted Rewards
asset code and issuer are configured, expose a numeric Rewards balance only when
exactly one non-native balance exists; otherwise fail closed to a safe label.

Step 10 implements the version-pinned RFC 4506 codec, limited transaction envelope,
network-passphrase transaction hashing, Ed25519 signature hints/signing/verification,
and preservation of existing signatures. It is private SDK protocol infrastructure
only; Step 11 remains responsible for building and signing the policy-approved live
activation response.
