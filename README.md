# theBuilderPros App

theBuilderPros App is theBuilderPros mobile companion for Builders. It provides a focused mobile view of Builder identity, Builder Rewards, followed Apps, and the work being shipped by App Squads.

Repository: https://github.com/theBuilderPros/TheFlutterBuilderProsApp

## Current status

The project is in its UI and navigation prototype phase. The screens and presentation interactions are implemented with local mock data.

Not implemented yet:

- authentication or user sessions
- Supabase or another backend data source
- persistence across app restarts
- real Rewards balances or transfers
- real QR generation or scanning
- notifications
- loading, error, offline, and unauthenticated states

Mock behavior must not be treated as production functionality.

## Implemented screens

### Home

- Builder identity and level
- Rewards balance
- followed Apps
- App work counts and detail navigation

### Rewards

- Rewards balance
- Receive and Send presentation modes
- QR placeholder and Reward ID
- mock recipient and amount fields

### Apps

- searchable App discovery
- App description and status
- WIP and completed Work counts
- following indicator

### App detail

- App overview
- follow and unfollow presentation state
- WIP
- Committed Work
- Work History
- Work Item outcome, cycle, week number, and week label

## Product language

The app follows Builder Workspace terminology:

- A Builder is the member identity.
- An App is the Builder-facing representation of a Squad/App.
- A Work Item is meaningful work that should ship, be demonstrated, or become professional evidence.
- Work states shown on mobile are Committed, WIP, and Done presented as Work History.
- Use Rewards, Builder Rewards, and Rewards Balance. Avoid wallet and Web3 language in Builder-facing UI.

The six Builder Cycle week labels are Download, Listen, Emerge, Experiment, Implement, and Launch.

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

There is currently no Supabase package, HTTP client, database, authentication package, or local persistence layer.

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
    |-- features/profile/             Current prototype shell and mock read model
    `-- widget/                       Shared widgets
```

The current prototype is consolidated in `ProfileScreen` and `ProfileController`. When backend logic begins, Home, Rewards, Apps, and App Detail should be extracted incrementally into focused feature modules.

## Planned integration

The intended direction is a shared Supabase backend used by the Electron Builder Workspace and the Flutter studio app:

```text
Electron Builder Workspace        theBuilderPros App
          |                                  |
       supabase-js                     supabase_flutter
          |                                  |
          +------ Supabase Auth/Postgres/RLS-+
```

Planned work:

1. introduce typed domain models and repository interfaces
2. add Supabase Auth and Builder profile loading
3. read Apps and participation through `squad_app` and `squad_builder`
4. read App work through `work_item` and `squad_work_item`
5. implement Rewards behind a security-reviewed service boundary
6. add loading, empty, error, offline, and unauthenticated states
7. expand widget and integration test coverage

Widgets must not call Supabase directly. Service-role keys, account secrets, recovery phrases, seeds, and privileged credentials must never ship in the client.

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
flutter test test\widget_test.dart --reporter expanded
```

Build a debug Android APK:

```powershell
flutter build apk --debug
```

Output:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

## Related system

The Electron Builder Workspace owns coordination and work execution workflows such as creating and managing Work Items. theBuilderPros App remains intentionally mobile-focused and read-oriented so Builders can follow Apps, review work updates, and access Rewards without reproducing the full desktop Workspace.
