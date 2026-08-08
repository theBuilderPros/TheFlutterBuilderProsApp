# Current State

Last synchronized: 2026-08-08

## Branch Truth

`main` is the current product branch for theBuilderStudio. This repository is no longer the old Week 1 profile challenge and does not use the inherited weekly branch narrative.

Canonical repository: `https://github.com/theBuilderUni/TheFlutterBuilderStudioApp.git`

## Runtime Truth

The app currently runs as a Flutter Material 3 application with GetX routing, dependency injection, and reactive state.

The primary registered route opens `ProfileScreen`, which presently acts as the main mobile shell. It contains:

- Home
- Rewards
- Apps
- App Squad detail
- bottom navigation between Home, Rewards, and Apps

An additional `MiniAppHostScreen` route hosts a bundled Vite mini app in WebView. It is opened from the Apps tab through the Mini App Host card.

`ProfileController` currently owns mock Builder, Squad/App, and Work Item records plus UI state for tabs, Rewards mode, search, selected App, and followed Apps.

## Implemented UI Behavior

- switch among the three bottom tabs
- view Builder profile and Rewards balance
- view followed Apps
- search mock Apps by name/description
- open and close App Squad detail
- follow/unfollow an App for the current runtime session
- switch between Rewards Receive and Send presentations
- display WIP, Committed Work, and Work History from linked mock Work Items
- open the bundled QuickPay mini app demo from a local phone URL
- exchange mock profile/Rewards messages between JavaScript and Flutter through a bridge

## Mock-Only Behavior

The current app has no persistence or external data source. The following are placeholders:

- Builder identity and level
- Rewards balance and Reward ID
- QR presentation
- Rewards send form/action
- App records and follow state
- Work Item records and counts
- notifications button
- mini app host actions and bridge responses

## Mini App Host Runtime

`MiniAppHostController` starts `MiniAppAssetServer`, which binds to `127.0.0.1` on a dynamic port and serves files from `assets/mini_app`.

The WebView loads that local URL. This is a phone-local runtime server for bundled assets, not a remote public host.

The copied mini app source lives in `mini_apps/quickpay_pass`. It remains a demo mini app and does not perform real Rewards operations.

## Platform Branding

- Dart package: `the_builder_studio`
- Android application ID: `com.thebuilderuni.thebuilderstudio`
- product name: `theBuilderStudio` / theBuilderStudio
- official logo: `assets/images/the_builder_uni_logo.png`
- Android launcher icons: branded density-specific PNGs
- web favicon: official Builder Uni logo

## Verification Status

The current implementation has passed:

- `flutter analyze`
- `flutter test test\widget_test.dart --reporter expanded`
- Android debug APK build

The mini app host change has also passed `flutter analyze`.

## Next Engineering Phase

The next phase is logic and integration, not additional speculative UI. Expected work:

1. split the consolidated prototype into focused Home, Rewards, Apps, and App Detail feature files
2. introduce typed repositories/services
3. add Supabase Auth and Builder profile loading
4. read Apps, participation links, and Work Items from the shared Workspace schema
5. implement real Rewards operations behind a safe service boundary
6. add loading, empty, error, unauthenticated, and offline states
7. expand unit, widget, and integration coverage
