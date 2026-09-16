# Decision Log

This log records current decisions that materially shape theBuilderPros. Superseded weekly/Talkware history was removed because it did not describe this repository.

## 2026-07-12 — Reset as theBuilderStudio

### Decision

Create a clean Flutter project identity and Git history for theBuilderStudio.

### Result

- package renamed to `the_builder_studio`
- Android ID set to `com.thebuilderuni.thebuilderstudio`
- new `main` history initialized
- canonical repository set to `https://github.com/theBuilderUni/TheFlutterBuilderStudioApp.git`

## 2026-07-12 — Preserve Flutter + GetX Foundation

### Decision

Retain GetX routing/state/DI plus `BaseController`, `BaseView`, bindings, and centralized resources.

### Reason

The existing foundation is small, working, and suitable for incremental service-backed evolution.

### Result

The current mobile shell remains registered through a centralized GetX route and feature binding.

## 2026-07-12 — Mobile Is a Builder-Facing Visibility Layer

### Decision

The mobile app will not reproduce the full Electron Workspace. It focuses on Builder identity, Rewards, App discovery, and read-only App work visibility.

### Result

Current screens are Home, Rewards, Apps, and App Detail. Desktop coordination/editing workflows remain out of scope.

## 2026-07-12 — Implement UI Before Logic

### Decision

Recreate the reference mobile screens first with mock data and add backend logic later.

### Reason

This establishes navigation, information hierarchy, brand direction, and expected read models before choosing integration details.

### Result

All current records, balances, follow state, QR presentation, and send behavior are non-persistent mocks.

## 2026-07-12 — Align With Workspace Data Concepts

### Decision

Use Builder, Squad/App, Work Item, and relationship-link concepts from the Workspace documentation.

### Result

The UI uses Apps, WIP, Committed Work, Work History, Outcome, Cycle, and Week labels. Task terminology is rejected for the mobile MVP.

## 2026-07-12 — Use Rewards Language

### Decision

Use Rewards, Builder Rewards, and Rewards Balance in Builder-facing UI. Avoid wallet and Web3 terminology.

### Result

Future technical implementation must preserve this product language and hide secret/recovery material.

## 2026-07-12 — Brand With Restraint

### Decision

Use the official orange/violet logo palette within a professional white/neutral interface.

### Result

- orange is reserved for primary actions/emphasis
- violet supports navigation, focus, and compact badges
- normal text is black
- cards are white with neutral borders/shadows
- colored card strips are prohibited
- page titles use a short mostly-orange underline with a small violet ending

## 2026-07-12 — Brand Native App Surfaces

### Decision

Use the official logo for the web favicon and Android launcher icon rather than Flutter defaults.

### Result

All Android density launcher resources and `web/favicon.png` are branded.

## 2026-07-13 — Shared Supabase Is the Intended Integration Direction

### Decision

When logic work begins, the Flutter app should read the same core Supabase data model as the Electron Workspace through typed repositories/services and RLS.

### Constraints

- no direct Supabase calls from generic widgets
- no service-role key in the client
- no system secrets, seeds, or recovery phrases in the app
- Work Items remain independent and relationships use link records

## 2026-07-13 — Treat Current Feature Consolidation as Prototype Debt

### Decision

Document the current broad `ProfileScreen`/`ProfileController` honestly, then split it incrementally during integration.

### Reason

The current implementation works, but copying the all-in-one pattern would make logic, testing, and maintenance harder.

## 2026-07-13 — Repository Renamed to TheFlutterBuilderStudioApp

### Decision

Align the GitHub repository name with the `theBuilderStudio` product identity.

### Result

The canonical remote is now `https://github.com/theBuilderUni/TheFlutterBuilderStudioApp.git`. The Dart package remains `the_builder_studio`, the user-facing name remains `theBuilderStudio`, and the Android application ID remains `com.thebuilderuni.thebuilderstudio`.

## 2026-09-16 - Rebrand to theBuilderPros

### Decision

Rename the current product and checked-in platform identities from theBuilderStudio to `theBuilderPros`.

### Result

- Dart package: `the_builder_pros`
- Android namespace/application ID: `com.thebuilderpros.thebuilderpros`
- iOS/macOS bundle ID: `com.thebuilderpros.thebuilderpros`
- Linux application ID: `com.thebuilderpros.thebuilderpros`
- desktop binary: `the_builder_pros`
- primary logo: `assets/images/the_builder_pros_logo.png`
- target repository: `https://github.com/theBuilderPros/TheFlutterBuilderProsApp.git`

The supplied horizontal text logo is used as-is. Derived square platform assets preserve the full wordmark and its aspect ratio with padding; no replacement monogram is used. User-facing text uses `theBuilderPros`, while the supplied logo artwork retains its original visual casing.

Legal owner, production email/domain, app-store registration, release signing, and external account configuration remain separate approvals and must not be invented in source.