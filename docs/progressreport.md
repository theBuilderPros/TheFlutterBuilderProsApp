# theBuilderPros Rebrand Progress Report

Last updated: 2026-09-16

## Status

Source rebrand implementation and GitHub repository rename are complete on the local `main` working tree. Verification passed for Flutter analysis, widget tests, Android debug APK, and web. Windows compilation is blocked by the missing Visual Studio desktop toolchain on this machine.

The authoritative checklist is `docs/thebuilderpros-rebrand-plan-final.md`.

## Implemented decisions

- Customer-facing name: `theBuilderPros`
- Dart package: `the_builder_pros`
- Android namespace/application ID: `com.thebuilderpros.thebuilderpros`
- iOS/macOS bundle ID: `com.thebuilderpros.thebuilderpros`
- Linux application ID: `com.thebuilderpros.thebuilderpros`
- Desktop binary: `the_builder_pros`
- GitHub repository: `https://github.com/theBuilderPros/TheFlutterBuilderProsApp`
- Local `origin`: `https://github.com/theBuilderPros/TheFlutterBuilderProsApp.git`
- Existing Flutter + GetX architecture and mock-only runtime scope preserved
- Supplied text logo used exactly as provided; no generated monogram is included or referenced

## Completed work

- [x] Copied and validated the supplied 2172 x 724 transparent text logo
- [x] Updated the in-app logo asset and centralized `AppImages` reference
- [x] Generated proportional, padded text-logo assets for Android, iOS, macOS, web/PWA, and Windows
- [x] Added an Android adaptive launcher icon using the supplied text logo
- [x] Renamed Dart package imports, app strings, mock brand copy, and widget-test description
- [x] Updated Android ID, namespace, Kotlin package path, display label, and launcher assets
- [x] Updated iOS app/test bundle IDs, display name, and AppIcon catalog
- [x] Updated macOS product/bundle/test identities, schemes, copyright placeholder, and AppIcon catalog
- [x] Updated web/PWA titles, descriptions, favicon, standard icons, and maskable icons
- [x] Updated Windows project/binary/window/resource metadata and multi-resolution icon
- [x] Updated Linux application ID, binary name, and window titles
- [x] Updated README, AGENTS instructions, current-state, architecture/design context, workflow rules, progress tracker, and decision log
- [x] Removed the obsolete Builder Uni logo asset
- [x] Renamed the GitHub repository to `TheFlutterBuilderProsApp`
- [x] Updated and verified the local Git remote
- [x] Updated the GitHub repository description with accurate mock-prototype wording
- [x] Completed the residual former-brand audit outside intentional historical/planning records

## Asset validation

- Source logo: 2172 x 724 ARGB PNG with transparent outer background
- Android legacy icons: expected density sizes confirmed
- Android adaptive foreground: 432 x 432 PNG
- Web favicon: 32 x 32 PNG
- Web/PWA icons: 192 x 192 and 512 x 512 PNGs
- iOS master icon: 1024 x 1024 PNG; all declared catalog images regenerated
- macOS master icon: 1024 x 1024 PNG; all declared catalog images regenerated
- Windows icon: valid six-image ICO container

All derived assets preserve the complete supplied text logo and aspect ratio. Square icon surfaces use padding rather than a monogram or redraw.

## Verification log

| Check | Result |
| --- | --- |
| `flutter pub get` | Passed |
| `dart format lib test` | Passed; 18 files checked, 2 formatted |
| `flutter analyze` | Passed |
| `flutter test test\widget_test.dart --reporter expanded` | Passed; 1 test |
| `flutter build apk --debug` | Passed; `build/app/outputs/flutter-apk/app-debug.apk` |
| `flutter build web` | Passed; `build/web` |
| `flutter build windows` | Blocked; Visual Studio desktop toolchain is not installed |
| Residual former-brand search | Passed outside intentional historical/planning records |

## Protected unknowns and external follow-up

- Confirm legal company/copyright owner, production email domain, website, support URL, and privacy URL. Neutral copyright text and `jordan@example.com` are used rather than invented legal/domain values.
- Confirm domain ownership and app-store availability for `com.thebuilderpros.thebuilderpros` before production registration.
- Configure production Android signing; the current Android project still uses debug signing for release builds.
- Register/update Google Play, App Store Connect, signing/provisioning, OAuth, Firebase, Supabase redirects, deep links, push, analytics, and CI/CD only if those systems are actually introduced.
- Build and verify iOS, macOS, and Linux on compatible toolchains.
- Install a Visual Studio desktop C++ toolchain before Windows build verification.
- Decide whether divergent `MiniAppStore` and `Wallet` branches remain maintained before changing or archiving them. No history was rewritten and no branch was deleted.
- Recheck GitHub branch protection, environments, webhooks, Apps, and external deployment integrations through organization administration if any are configured.

## Publication status

The repository has been renamed, the local remote is correct, and the verified rebrand source is prepared for publication to remote `main`.