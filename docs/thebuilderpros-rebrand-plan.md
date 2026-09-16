# theBuilderPros Rebrand Plan

> Superseded for execution by `docs/thebuilderpros-rebrand-plan-final.md`.


Status: proposed implementation plan  
Prepared: 2026-09-16  
Scope: rename and rebrand the current Flutter application from `theBuilderStudio` / The Builder Uni branding to `theBuilderPros`, including package/application identifiers and platform assets.

## 1. Target identity

Use the following values consistently unless a platform constraint requires a different format:

| Concern | Current | Target |
| --- | --- | --- |
| User-facing product name | `theBuilderStudio` | `theBuilderPros` |
| Dart/Flutter package name | `the_builder_studio` | `the_builder_pros` |
| Android namespace/application ID | `com.thebuilderuni.thebuilderstudio` | `com.thebuilderpros.thebuilderpros` |
| iOS/macOS bundle ID | `com.thebuilderuni.thebuilderstudio` | `com.thebuilderpros.thebuilderpros` |
| Linux application ID | `com.thebuilderuni.thebuilderstudio` | `com.thebuilderpros.thebuilderpros` |
| Desktop binary name | `the_builder_studio` | `the_builder_pros` |
| Primary logo asset | `assets/images/the_builder_uni_logo.png` | `assets/images/the_builder_pros_logo.png` |
| In-code logo constant | existing Builder Uni logo constant | `AppImages.theBuilderProsLogo` |
| Repository name/URL | `TheFlutterBuilderStudioApp` | proposed `TheFlutterBuilderProsApp` |

The exact brand spelling in customer-facing copy is `theBuilderPros` (lowercase `t`, uppercase `B` and `P`). Package names, executable names, and filenames use snake case where required.

### Decisions to confirm before implementation

1. Confirm ownership and availability of `com.thebuilderpros.thebuilderpros`. Changing an application/bundle ID causes Android and Apple stores to treat the build as a different app; it does not update an already-published app in place.
2. Confirm whether the GitHub repository should be renamed to `TheFlutterBuilderProsApp` and whether the GitHub organization remains `theBuilderUni` or also changes.
3. Confirm whether `@thebuilderuni.com`, "The Builder Uni", and other organization/domain references should become a new legal/company/domain identity. Do not invent a new email domain or copyright owner.
4. Supply or approve a square app-icon treatment. The supplied `TheBuilderPros Logo.png` is a wide wordmark (2172 x 724) and should not be stretched or squeezed into a launcher icon.

## 2. Brand asset preparation

1. Copy the supplied source logo from `C:\Users\USER\Downloads\TheBuilderPros Logo.png` into the repository as `assets/images/the_builder_pros_logo.png`.
2. Preserve the original aspect ratio and transparency. Remove unintended empty canvas only if visual inspection confirms it is safe.
3. Update `pubspec.yaml` asset declarations if the current directory-level declaration does not already cover the new file.
4. Update `AppImages` and all widget references to use the new asset. Remove the old logo only after a repository-wide search confirms there are no remaining references.
5. Produce and visually verify platform-specific assets from approved source artwork:
   - Android launcher icons for all existing `mipmap-*` densities, preferably including adaptive foreground/background resources.
   - iOS AppIcon asset catalog at every size declared by `Contents.json`.
   - macOS AppIcon asset catalog.
   - Windows `app_icon.ico` with multiple embedded sizes.
   - Web favicon plus 192 px, 512 px, and maskable PWA icons.
6. Check every generated icon at small size, on light and dark system backgrounds, and inside platform safe areas. Do not use the wide wordmark as-is where a square icon is required.

## 3. Flutter and Dart rename

1. Change `pubspec.yaml`:
   - `name` to `the_builder_pros`.
   - description to approved theBuilderPros wording.
2. Replace every `package:the_builder_studio/...` import in `lib/` and `test/` with `package:the_builder_pros/...`.
3. Change `AppString.appName` to `theBuilderPros` and update any direct UI strings that still say `theBuilderStudio`, "Builder Uni Mobile", or otherwise present the old product name.
4. Keep domain terms such as Builder, App, Work Item, Rewards, WIP, Committed, and Work History unless product requirements explicitly redefine them.
5. Update widget-test names and expectations to the new product name without changing mock-only behavior into production claims.
6. Run `flutter pub get` so generated package metadata reflects the new Dart package name.

## 4. Platform identity migration

### Android

1. Update `namespace` and `applicationId` in `android/app/build.gradle.kts`.
2. Move `MainActivity.kt` from `com/thebuilderuni/thebuilderstudio/` to the directory matching the new namespace and update its `package` declaration.
3. Change `android:label` in `android/app/src/main/AndroidManifest.xml` to `theBuilderPros`.
4. Replace launcher resources and verify debug/profile manifests do not contain stale authorities or IDs.

### iOS

1. Replace app and test-target `PRODUCT_BUNDLE_IDENTIFIER` values in the Xcode project.
2. Update `CFBundleDisplayName` and `CFBundleName` to `theBuilderPros`.
3. Replace the AppIcon catalog and verify signing/capability identifiers after the bundle-ID change.

### macOS

1. Update `PRODUCT_NAME`, `PRODUCT_BUNDLE_IDENTIFIER`, copyright text, product references, scheme buildable names, and test-host paths.
2. Replace the macOS AppIcon catalog.

### Web

1. Update title, Apple web-app title, description, manifest `name`, `short_name`, and description.
2. Replace favicon and all PWA icon variants.
3. Verify install-banner and browser-tab presentation.

### Windows

1. Rename the CMake project and binary.
2. Update the window title and the CompanyName, FileDescription, InternalName, OriginalFilename, ProductName, and copyright resources.
3. Replace the multi-resolution `.ico` file.

### Linux

1. Rename `BINARY_NAME`, update `APPLICATION_ID`, and update window/header titles.
2. Verify the resulting desktop file/application registration when a Linux build environment is available.

## 5. Copy and data audit

Perform a case-insensitive repository-wide audit for at least:

```text
theBuilderStudio
the_builder_studio
thebuilderstudio
Builder Studio
The Builder Uni
Builder Uni
theBuilderUni
thebuilderuni
com.thebuilderuni
TheFlutterBuilderStudioApp
the_builder_uni_logo
```

Classify each result before changing it:

- Product identity: rename to theBuilderPros.
- Organization/legal identity: change only after the owner/domain decision is confirmed.
- Historical record: retain the old value when needed for an accurate migration history, explicitly marking it as the former identity.
- Mock content: update only when it is intended to demonstrate the product brand; do not fabricate domains or implemented functionality.
- Generated/build output: regenerate or clean; do not hand-edit generated files.

Known source locations currently include `lib/`, `test/`, `pubspec.yaml`, all six Flutter platform folders, `README.md`, `AGENTS.md`, and every file under `context/`.

## 6. Documentation and repository updates

1. Rewrite the README title, description, identity table, setup examples, asset references, and clone URL after the repository rename is complete.
2. Update `AGENTS.md` product/branding rules while preserving architecture, terminology, security, and verification rules.
3. Synchronize:
   - `context/current-state.md`
   - `context/project-overview.md`
   - `context/architecture.md`
   - `context/code-standards.md` where asset naming examples change
   - `context/ui-context.md`
   - `context/progress-tracker.md`
   - `context/decision-log.md`
   - `context/ai-workflow-rules.md` if the canonical remote changes
4. Add a dated decision-log entry describing the old and new identities, selected IDs, asset source, repository rename, and store-migration consequence.
5. Rename the GitHub repository and update the local `origin` only after the target name and organization are confirmed. Preserve history; do not recreate or force-push the repository.

## 7. External configuration checklist

The repository currently has no implemented authentication or backend integration, but the identifier change must be propagated to any external configuration introduced before release:

- Google Play and Apple Developer/App Store Connect app records
- signing profiles, provisioning profiles, and certificates
- OAuth client IDs and redirect URIs
- Firebase/Google service configuration files
- Supabase redirect allowlists and deep links
- push-notification entitlements and provider records
- universal links/app links and associated-domain files
- CI/CD secrets, artifact names, deployment jobs, and release automation
- analytics, crash reporting, and distribution services

Never commit service credentials while performing the migration.

## 8. Implementation sequence

1. Record confirmed target identifiers, repository location, organization/domain wording, and square-icon artwork.
2. Add and validate the new source artwork.
3. Rename Flutter package imports and centralized strings.
4. Update Android, iOS, macOS, web, Windows, and Linux identities.
5. Generate and install every required icon/favicon asset.
6. Update tests, README, AGENTS instructions, and context documentation.
7. Run the residual-name audit and manually classify any intentional historical matches.
8. Format and verify the project.
9. Build platform artifacts where toolchains are available.
10. Rename/update the remote repository last, after the local code and documentation consistently use the new identity.

## 9. Verification and acceptance criteria

Run these commands independently from the project root:

```powershell
flutter pub get
dart format lib test
flutter analyze
flutter test test\widget_test.dart --reporter expanded
flutter build apk --debug
flutter build web
```

Also perform platform builds for iOS, macOS, Windows, and Linux on compatible hosts/toolchains when those platforms are release targets.

The rebrand is complete when:

- all user-visible product naming is `theBuilderPros` with approved casing;
- Dart imports resolve under `the_builder_pros`;
- every supported platform uses the approved new identifier and display name;
- the supplied wordmark appears correctly in the UI without distortion;
- every icon/favicon is derived from approved square artwork and passes visual inspection;
- searches find no unintended old identity strings or obsolete logo references;
- documentation accurately distinguishes existing mock behavior from planned integrations;
- analysis, tests, Android build, and web build pass;
- the canonical remote and documentation agree, if the repository is renamed.

## 10. Rollback preparation

Implement the migration in focused commits: source artwork, Flutter rename, platform identifiers/assets, then documentation/repository metadata. Before publishing a build with new IDs, tag or otherwise record the last verified pre-rebrand commit. If identifiers must change after store registration, correct them before public release to avoid creating additional app records.
