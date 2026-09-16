# theBuilderPros Rebrand Plan — Reconciled Final

Status: authoritative implementation plan  
Prepared: 2026-09-16  
Supersedes for execution:

- `docs/thebuilderpros-rebrand-plan.md`
- `docs/thebuilderpros-github-rebrand-addendum.md`

The two earlier documents remain useful audit history, but this file resolves their discrepancies and combines product, code, platform, asset, store, and GitHub work into one checklist.

## 1. Confirmed current state

- Product/display name: `theBuilderStudio`
- Dart package: `the_builder_studio`
- Android application ID and namespace: `com.thebuilderuni.thebuilderstudio`
- iOS/macOS bundle ID: `com.thebuilderuni.thebuilderstudio`
- Linux application ID: `com.thebuilderuni.thebuilderstudio`
- Desktop binary: `the_builder_studio`
- Current logo asset: `assets/images/the_builder_uni_logo.png`
- Current GitHub repository: `https://github.com/theBuilderPros/TheFlutterBuilderStudioApp`
- Confirmed GitHub organization: `theBuilderPros`
- Local `origin` still points to `https://github.com/theBuilderUni/TheFlutterBuilderStudioApp.git`
- Remote branches observed on 2026-09-16: `main`, `production`, `MiniAppStore`, and `Wallet`
- `main` and `production` referenced the same commit when audited; `MiniAppStore` and `Wallet` referenced different commits. Recheck immediately before migration because branch state can change.
- Runtime behavior remains a local mock-data prototype. Rebranding must not turn mock claims into production claims.

## 2. Target identity and approval gates

| Concern | Target |
| --- | --- |
| User-facing product name | `theBuilderPros` |
| Dart package | `the_builder_pros` |
| Proposed Android namespace/application ID | `com.thebuilderpros.thebuilderpros` |
| Proposed iOS/macOS bundle ID | `com.thebuilderpros.thebuilderpros` |
| Proposed Linux application ID | `com.thebuilderpros.thebuilderpros` |
| Desktop binary | `the_builder_pros` |
| Primary runtime logo | `assets/images/the_builder_pros_logo.png` |
| In-code logo constant | `AppImages.theBuilderProsLogo` |
| Proposed final repository | `https://github.com/theBuilderPros/TheFlutterBuilderProsApp` |

Do not implement irreversible or externally registered identity changes until these decisions are recorded:

1. Confirm that `com.thebuilderpros.thebuilderpros` is the intended identifier, that the organization controls the corresponding reverse-domain namespace, and that it is available in each target store. The GitHub organization name alone does not prove domain ownership or store availability.
2. Confirm whether this is a new store app or must update an existing published app. Changing an Android application ID or Apple bundle ID creates a distinct installed/store identity and normally prevents an in-place update of the old app.
3. Confirm the repository rename to `TheFlutterBuilderProsApp`.
4. Confirm the legal organization name, copyright owner, email domain, support URL, privacy URL, and website. Do not mechanically turn `thebuilderuni.com` into an unverified domain or use an application ID as a legal company name.
5. Brand casing decision: user-facing text uses `theBuilderPros`; the supplied wordmark is used exactly as provided and keeps its original visual casing.
6. Icon decision: use the supplied 2172 x 724 horizontal text logo as-is. For square platform slots, preserve the full wordmark and aspect ratio with black padding; do not create a monogram or redraw the logo.
7. Decide which platforms are actual release targets. Update all checked-in platform identities for consistency, but require release builds and store work only for supported targets.
8. Decide the release version/build-number strategy for the rebrand.

## 3. Source artwork and asset production

1. Copy `C:\Users\USER\Downloads\TheBuilderPros Logo.png` to `assets/images/the_builder_pros_logo.png` after resolving casing approval.
2. Keep an untouched source copy or recorded checksum for provenance. Preserve aspect ratio and transparency; never stretch the wordmark.
3. Inspect transparent bounds and crop only unintended empty canvas. Produce a size-optimized runtime derivative if the source is excessive for the in-app header.
4. Replace `AppImages.logo` with an explicitly named `AppImages.theBuilderProsLogo`, update consumers, and remove the old asset only after a residual-reference audit.
5. Produce platform assets from the supplied text logo without altering its design:
   - Android legacy density icons and, where supported, adaptive foreground/background plus monochrome icon resources
   - iPhone/iPad AppIcon sizes declared by the iOS asset catalog
   - macOS AppIcon sizes declared by its asset catalog
   - Windows multi-resolution `.ico`
   - web favicon, Apple touch icon, 192 px and 512 px PWA icons, and maskable variants
   - Linux desktop/package icon if Linux distribution packaging is in scope
6. Keep the entire text logo within maskable/adaptive safe zones, preserve its aspect ratio, and use black padding. Verify icons at small sizes and on light/dark system surfaces.
7. Audit Android launch backgrounds, iOS launch storyboard/images, and desktop startup surfaces. Apply approved branding or verify that neutral launch assets contain no former identity.
8. Confirm palette tokens against the approved new brand. Do not assume the existing orange/violet values are unchanged solely because the supplied logo appears similar.

## 4. Flutter and Dart changes

1. Update `pubspec.yaml`:
   - package `name` to `the_builder_pros`
   - description to approved theBuilderPros language
   - version/build number if required by the release decision
2. Replace all `package:the_builder_studio/...` imports in `lib/` and `test/`.
3. Update `AppString.appName` and all direct product-name strings to `theBuilderPros`.
4. Review mock content such as `Builder Uni Mobile` and `jordan@thebuilderuni.com`. Replace only with approved organization/domain copy; otherwise use clearly fictional neutral mock data.
5. Preserve domain vocabulary: Builder, App, Squad/App where explanatory, Work Item, Rewards, WIP, Committed, and Work History.
6. Update test descriptions and expectations without claiming authentication, persistence, Supabase, real QR, notifications, or real Rewards transfers.
7. Run `flutter pub get` and review generated dependency/package metadata. Do not hand-edit Flutter-generated metadata unnecessarily.

## 5. Native and web platform changes

### Android

1. Update `namespace` and `applicationId` in `android/app/build.gradle.kts`.
2. Move `MainActivity.kt` to the directory matching the new namespace and update its package declaration.
3. Change the manifest application label to `theBuilderPros`.
4. Replace legacy/adaptive/monochrome launcher resources as applicable.
5. Audit debug and profile manifests, content-provider authorities, intent filters, deep links, permissions tied to package names, ProGuard/R8 rules, and generated service configuration if any are added before release.
6. Replace debug signing for release builds with the approved release-signing process; do not commit keystores or passwords.

### iOS

1. Update app and test-target bundle identifiers in the Xcode project.
2. Update `CFBundleDisplayName` and `CFBundleName`.
3. Replace the complete AppIcon catalog and audit launch assets/storyboard.
4. Review schemes, signing team, provisioning, entitlements, associated domains, URL schemes, and service configuration for the new bundle ID.

### macOS

1. Update `PRODUCT_NAME`, bundle IDs for app/test targets, Xcode product references, scheme buildable names, and test-host paths.
2. Replace the complete AppIcon catalog.
3. Update copyright/company values only after legal identity approval.
4. Review signing, entitlements, sandbox capabilities, and notarization configuration.

### Web/PWA

1. Update HTML title, metadata description, Apple web-app title, manifest `name`, `short_name`, and description.
2. Replace favicon, Apple touch icon, regular PWA icons, and maskable icons.
3. Confirm brand-approved `theme_color` and `background_color` instead of assuming existing values remain correct.
4. Verify base path, start URL, installed-app title, offline caching behavior, and icon presentation when served from the intended production path.

### Windows

1. Update the CMake project/binary name and window title.
2. Update FileDescription, InternalName, OriginalFilename, and ProductName resources.
3. Replace the multi-resolution application icon.
4. Update CompanyName and LegalCopyright only after legal identity approval.
5. Review installer/MSIX identity, publisher, signing certificate, shortcuts, upgrade behavior, and uninstall identity if Windows packaging is introduced or already maintained elsewhere.

### Linux

1. Update `BINARY_NAME`, GTK application ID, and window/header titles.
2. If Linux distribution is supported, update desktop entry, icon, package ID/name, AppStream metadata, and installer/package scripts.

## 6. Repository-wide copy audit

Search case-insensitively through tracked source and configuration files for:

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
FlutterBuilderStudio
```

Also search for the old GitHub URL and old email/domain values explicitly. Audit filenames and directory names as well as file contents.

Classify matches before editing:

- product identity: rename
- organization/legal identity: change only to approved legal/domain values
- current configuration: migrate
- mock data: use approved or clearly fictional values
- historical migration record: retain when necessary and label as former identity
- generated/build output: regenerate or clean rather than hand-edit

Known locations include `lib/`, `test/`, `pubspec.yaml`, Android, iOS, macOS, web, Windows, Linux, `README.md`, `AGENTS.md`, and every file under `context/`. Rename local workspace/clone folders and external scripts only if they encode the former product identity; do not rename unrelated parent directories automatically.

## 7. Documentation synchronization

1. Rewrite the README title, summary, technical identity table, design/asset references, setup commands, clone URL, and related-system wording.
2. Update `AGENTS.md` product and brand rules while preserving architecture, domain terminology, security boundaries, verification rules, and the warning that runtime data is mocked.
3. Synchronize all context documents:
   - `context/current-state.md`
   - `context/project-overview.md`
   - `context/architecture.md`
   - `context/code-standards.md`
   - `context/ui-context.md`
   - `context/progress-tracker.md`
   - `context/decision-log.md`
   - `context/ai-workflow-rules.md`
4. Add a dated decision-log entry recording former and new identities, approved identifiers, legal/domain decisions, logo/icon sources, repository rename, release version, and store migration consequences.
5. Keep documentation honest about mock-only behavior and planned integrations.

## 8. GitHub migration

1. Rename the repository through GitHub settings after approving `TheFlutterBuilderProsApp`. Preserve the repository; do not recreate it or rewrite shared history.
2. Update local `origin` after the rename:

   ```powershell
   git remote set-url origin https://github.com/theBuilderPros/TheFlutterBuilderProsApp.git
   git remote -v
   git ls-remote origin
   ```

3. Update the About description, website, topics, README clone link, badges, templates, contribution/security/support files, releases, artifact names, Pages settings, and package metadata.
4. Audit Actions workflows, reusable workflow references, cache keys, variables, environments, deployment jobs, GitHub Apps, deploy keys, webhooks, rulesets, branch protection, Actions permissions, and external CI/CD integrations. Secret values may be unreadable by design; verify their consumers without exposing or copying secrets.
5. Recheck branches immediately before migration. Decide whether `production`, `MiniAppStore`, and `Wallet` are maintained and what deployment depends on them. Rebrand every maintained branch; archive or delete only with explicit approval.
6. Search current collaboration surfaces—active issues/PRs, templates, wiki, discussions, Projects, releases, and organization links. Preserve closed historical records rather than rewriting them misleadingly; update current instructions and active references.
7. Verify GitHub's redirect from the former URL, but update all controlled links. A redirect is not a permanent substitute for canonical URLs and can be disrupted if the old path is reused.
8. Confirm the default branch remains `main` and verify deployment targets after the rename.

## 9. External/store configuration

Update applicable external systems only after identifiers and legal details are approved:

- Google Play Console and App Store Connect records, listing name, descriptions, icons/screenshots, support/privacy URLs, and category metadata
- Android signing, Apple certificates/profiles, macOS signing/notarization, and Windows signing/publisher identity
- OAuth clients and redirect URIs
- Firebase/Google service files
- Supabase redirect allowlists and deep links
- app links, universal links, custom URL schemes, and associated-domain files
- push-notification credentials and entitlements
- analytics, crash reporting, distribution, monitoring, and feature-flag systems
- CI/CD secrets, variables, environments, artifact names, and release automation
- domain/DNS, support email, privacy policy, terms, and marketing/download pages

No such integration should be claimed as present merely because it appears in this checklist. Never commit private credentials, service-role keys, signing secrets, or recovery material.

## 10. Execution order

1. Record approvals for legal/domain values, IDs, platforms, versioning, repository name, and branch scope. The supplied text-logo-only direction is confirmed.
2. Create a focused pre-migration tag or release reference without rewriting history.
3. Add and visually validate source artwork and platform derivatives.
4. Rename the Dart package, imports, centralized strings, tests, and mock brand copy.
5. Update native/web identities, launch surfaces, icons, and platform metadata.
6. Synchronize README, AGENTS instructions, context, and GitHub-specific files.
7. Run the residual-name audit and classify every remaining match.
8. Format, analyze, test, and build supported targets independently.
9. Review maintained remote branches and resolve rebrand conflicts.
10. Rename the GitHub repository, update local and external remotes/links, and verify repository settings/integrations.
11. Register or update store/external identities and complete release verification.

## 11. Verification

Run independently from the project root:

```powershell
flutter pub get
dart format lib test
flutter analyze
flutter test test\widget_test.dart --reporter expanded
flutter build apk --debug
flutter build web
```

Where toolchains and release scope permit, also run platform builds for iOS, macOS, Windows, and Linux. For a release, additionally verify release-mode signing and artifacts rather than relying only on debug builds.

Perform manual checks for:

- exact visible spelling/casing on every screen and platform shell
- no distortion, clipping, excess transparent padding, or unsafe icon masks
- launch/splash surfaces
- installed app name and icon
- web browser/PWA install metadata
- desktop executable and file properties
- narrow-screen overflow and accessibility semantics
- upgrade/install behavior appropriate to the selected identifier strategy
- final GitHub remote, branches, protections, Actions, integrations, and canonical links

## 12. Completion criteria

The rebrand is complete only when:

- all approved user-visible product references use `theBuilderPros`, with any logo-only casing exception explicitly documented;
- package imports and supported platform identifiers use approved values;
- legal/company/domain fields use verified values rather than guesses;
- the supplied wordmark and approved square artwork are used in appropriate contexts;
- all supported platform assets, launch surfaces, metadata, signing, and store records are consistent;
- no unintended former-brand strings, paths, assets, URLs, or active branch content remain;
- mock behavior is still described honestly;
- required analysis, tests, builds, and visual checks pass;
- GitHub repository, local remote, documentation, branches, automation, and integrations agree on the final identity;
- no secrets or private signing material were committed.

## 13. Rollback and release safety

- Keep changes in focused commits: artwork, Flutter rename, platform identities, documentation/GitHub metadata, then external release configuration.
- Record the last verified pre-rebrand commit with a non-destructive tag or release reference.
- Do not force-push or rewrite shared history.
- Correct application IDs before public registration/release where possible. Once a new ID is registered or distributed, changing it again can create another distinct app identity.
- A code rollback cannot make a build with a new application ID become an update to the old installed app. Treat identifier approval as a release gate, not merely a reversible text edit.
