# theBuilderPros App

theBuilderPros App is theBuilderPros mobile Rewards prototype for Builders and App Masters.

Repository: https://github.com/theBuilderPros/TheFlutterBuilderProsApp

## Current status

The first functional Wallet SDK slice creates, protects, persists, restores, and renders a Builder activation request. The remaining screens are presentation prototypes using local mock data.

Not implemented yet:

- authentication or user sessions
- backend data source
- real Rewards balances or transfers
- QR scanning or QR-image import
- notifications
- loading, error, offline, and unauthenticated states

Mock behavior must not be treated as production functionality.

## Implemented screens

### Rewards

- Builder name and phone capture for first-time activation
- generated public activation-request QR preview
- activation QR scan/image-import and setup review
- Rewards balance
- Receive and Send presentation screens
- QR placeholder and Reward ID
- mock recipient and amount fields

### App Master

- activation-capacity and Rewards summaries
- Builder access list with Rewards balances and activation status
- activation-request camera/import entry points
- activation-package review and activation-QR image-save preview
- Advanced tab for App Master-only NOWNodes setup, rotation, and safe service information
- switch into the shared Builder Rewards surface for two-role testing

## Product language

- A Builder is the member identity.
- Use Rewards, Builder Rewards, and Rewards Balance in Builder-facing UI.
- Keep provider-specific implementation terminology out of Builder UI and normal
  App Master flows. NOWNodes setup is allowed only in App Master Advanced.
- Expose Rewards capabilities to application code only through the simple Wallet
  SDK facade and safe product-facing models.

## Design system

The UI uses theBuilderPros logo and brand palette in a restrained professional layout:

- white cards and navigation surfaces
- neutral light page background
- solid black typography
- orange for primary actions and focused emphasis
- violet for navigation selection, focus states, badges, and small accents
- neutral borders, rounded controls, and subtle shadows
- no decorative colored strips on cards

Core design resources live in `lib/app/constant/resources/`. Android launcher icons and the web favicon use the official theBuilderPros logo.

## Technical identity

| Setting | Value |
| --- | --- |
| Product name | `theBuilderPros` |
| Dart package | `the_builder_pros` |
| Android application ID | `com.thebuilderpros.thebuilderpros` |
| Version | `1.0.0+1` |
| Primary branch | `main` |

## Stack

- Flutter and Dart `^3.9.2`
- Material 3
- GetX `^4.7.2` for routing, dependency injection, and reactive state
- Material Icons
- `flutter_test` for widget testing

There is currently no backend client, database, authentication package, or local persistence layer.

## Project structure

```text
lib/
|-- main.dart                         Application entry point
|-- main_app.dart                     GetMaterialApp configuration
`-- app/
    |-- constant/
    |   |-- resources/                Colors, theme, strings, images, dimensions
    |   `-- routing/                  Central GetX route definitions
    |-- core/                         BaseController, BaseView, initial binding
    `-- features/
        |-- app_master/               App Master activation and diagnostics prototype
        |-- wallet/                   Shared User Wallet Rewards prototype
        `-- profile/widget/           Builder identity component
```

All application features belong under `lib/app/features/`. Wallet remains the initial route and owns the Builder Rewards experience. App Master owns activation management and its isolated Advanced diagnostics. Profile owns the Builder identity component used by activation.

## Planned work

1. Introduce typed wallet domain models and repository interfaces.
2. Add authentication and Builder identity loading.
3. Implement Rewards behind a security-reviewed service boundary.
4. Add loading, empty, error, offline, and unauthenticated states.
5. Expand widget and integration test coverage.

Widgets must not call external data sources directly. Account secrets, recovery phrases, seeds, and privileged credentials must never ship in the client.

## Getting started

Requirements:

- Flutter SDK compatible with Dart `^3.9.2`
- Android Studio or another configured Flutter target

```powershell
git clone https://github.com/theBuilderPros/TheFlutterBuilderProsApp.git
cd TheFlutterBuilderProsApp
flutter pub get
flutter devices
flutter run
```

## Verification

Run Flutter checks independently from the repository root:

```powershell
flutter analyze
flutter test
```

Build a debug Android APK:

```powershell
flutter build apk --debug
```

Output:

```text
build/app/outputs/flutter-apk/app-debug.apk
```
