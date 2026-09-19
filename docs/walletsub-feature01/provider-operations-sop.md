# Provider Operations SOP

## Scope

This procedure covers the App Master NOWNodes credential used by the Wallet SDK.
The key must remain in protected device storage and must never be committed,
logged, copied into diagnostics, screenshots, support messages, or UI state.

## Provisioning and restrictions

1. Create a dedicated provider key for each environment and restrict it to only
   the required Stellar endpoints where the provider supports restrictions.
2. Record the owner, environment, creation date, provider quota, and next review
   date outside the application. Never record the key itself in project files.
3. Import the key through App Master Advanced and confirm the SDK reports healthy.
4. Monitor authorization failures, throttling, quota consumption, and unexpected
   traffic in the provider console. Treat unexplained usage as compromise.

## Rotation

1. Create a replacement key and keep the previous key active.
2. On each Builder phone, create a settings request QR.
3. On App Master, inspect the request and create the signed update QR.
4. On the originating Builder phone, inspect and apply the update. Confirm the
   version increased and service health passed.
5. Repeat for all active phones. After the agreed overlap window and verification,
   revoke the previous key in the provider console.

Failed, expired, replayed, wrong-device, wrong-environment, or older updates must
not replace the active configuration. Never shorten the overlap window until all
offline devices have either rotated or been explicitly retired.

## Incident response

1. Create and provision a replacement key immediately.
2. Revoke the suspected key after the shortest safe overlap window.
3. Review provider usage and affected device inventory.
4. Remove distributor authority from any lost App Master device and rotate all
   credentials accessible to that device.

## Release gate

Production remains blocked until two physical devices pass testnet activation and
rotation, Android/iOS permissions are reviewed, and the security review approves
credential import, cryptography, transaction allow-listing, storage restoration,
and compromised-device limitations.
