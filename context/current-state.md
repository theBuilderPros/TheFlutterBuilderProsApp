# Current State

Last synchronized: 2026-09-16

## Branch Truth

`main` is the current product branch for theBuilderPros. This repository is no longer the old Week 1 profile challenge and does not use the inherited weekly branch narrative.

Canonical repository: `https://github.com/theBuilderPros/TheFlutterBuilderProsApp.git`

## Runtime Truth

The app currently runs as a Flutter Material 3 application with GetX routing, dependency injection, and reactive state.

The single registered route opens `ProfileScreen`, which presently acts as the complete mobile shell. It contains:

- Home
- Rewards
- Apps
- App Squad detail
- bottom navigation between Home, Rewards, and Apps

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

## Mock-Only Behavior

The current app has no persistence or external data source. The following are placeholders:

- Builder identity and level
- Rewards balance and Reward ID
- QR presentation
- Rewards send form/action
- App records and follow state
- Work Item records and counts
- notifications button

## Platform Branding

- Dart package: `the_builder_pros`
- Android application ID: `com.thebuilderpros.thebuilderpros`
- product name: `theBuilderPros` / theBuilderPros
- official logo: `assets/images/the_builder_pros_logo.png`
- Android launcher icons: branded density-specific PNGs
- web favicon: official theBuilderPros logo

## Verification Status

The rebranded implementation passed on 2026-09-16:

- `flutter analyze`
- `flutter test test\widget_test.dart --reporter expanded`
- Android debug APK build

## Next Engineering Phase

The next phase is logic and integration, not additional speculative UI. Expected work:

1. split the consolidated prototype into focused Home, Rewards, Apps, and App Detail feature files
2. introduce typed repositories/services
3. add Supabase Auth and Builder profile loading
4. read Apps, participation links, and Work Items from the shared Workspace schema
5. implement real Rewards operations behind a safe service boundary
6. add loading, empty, error, unauthenticated, and offline states
7. expand unit, widget, and integration coverage
