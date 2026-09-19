# Architecture Context

## Stack

| Layer | Technology | Role |
| --- | --- | --- |
| UI framework | Flutter / Dart `^3.9.2` | Cross-platform application UI |
| Design system | Material 3 | Theme, navigation, controls, and typography |
| State and DI | GetX `^4.7.2` | Reactive state, bindings, dependency injection, and routing |
| Icons | Material Icons | Application iconography |
| Testing | `flutter_test` | Unit and widget testing |

Dependency versions are authoritative in `pubspec.yaml`.

## Application Structure

1. `lib/main.dart` starts the application.
2. `lib/main_app.dart` creates `GetMaterialApp`, applies the theme and initial binding, and registers centralized routes.
3. All application features live under `lib/app/features/` and use screen, controller, binding, and feature-local widget folders as needed.
4. Shared resources live under `lib/app/constant/`.
5. Shared base abstractions and application bindings live under `lib/app/core/`.
6. Feature-owned reusable widgets stay under that feature's `widget/` folder. Introduce `lib/app/widget/` only for components that are genuinely shared across unrelated features.

Wallet and App Master are the active presentation features. Wallet owns the shared User Wallet experience. App Master owns the Distributor Dashboard and activation-package presentation while linking to the same Wallet routes for user-role testing. Reusable Builder identity components live under `lib/app/features/profile/widget/`.

Recommended feature shape:

```text
lib/app/features/{feature}/
|-- binding/
|-- controller/
|-- screen/
`-- widget/
```

Folders are capability-driven rather than mandatory. For example, Profile currently contains only `widget/`; its screen, controller, binding, and route should be introduced only when a standalone Profile capability returns.

Features with several route-level screens may group them by user journey below `screen/`. The Wallet feature uses `activation/`, `overview/`, `receive/`, `send/`, `history/`, and `security/`. Each route-level screen has its own file; flow barrels and the top-level `wallet_screens.dart` contain exports only. Route-level screen implementations must not be consolidated back into barrel files.

See `current-state.md` for the exact runtime composition.

## State and Presentation Boundary

- Route-level controllers extend `BaseController`.
- Route-level screens extend `BaseView<T>`.
- GetX bindings own controller registration.
- Views observe reactive state with `Obx`.
- State mutations belong in controllers or services, not presentation widgets.
- Process-local UI state must not be treated as persistence.

## Data Boundary

Widgets must not access a backend directly. External data flows through typed services or repositories for concerns such as:

- authentication and sessions
- Builder profiles
- Rewards balances and operations

Map transport records to typed DTOs or domain models at the data boundary.

Rewards features depend only on a small `WalletSdk` facade and safe,
product-facing models. Screens and controllers treat QR values as opaque and must
not import SDK implementation libraries. Credential protection, QR inspection,
activation rules, completion, verification, provider communication, and detailed
diagnostics remain private to the SDK.

The production backend and authorization design are not yet selected. Private account material and privileged credentials must never ship in the app.

## Resource Boundaries

- `AppColors`: brand and semantic colors
- `AppTheme`: Material component and typography themes
- `AppDimens`: reusable dimensions
- `AppString`: application strings
- `AppImages`: asset paths
- `assets/images/`: bundled image assets
- Native platform directories: launcher, package, and application branding

Visual rules and token values belong in `ui-context.md`. Current limitations belong in `current-state.md`; actionable architecture work belongs in `progress-tracker.md`.
