# AGENTS.md

## Purpose

This repository contains **theBuilderPros**, the Flutter mobile companion for theBuilderPros. It is a Builder-facing visibility layer for profile, Rewards, App discovery, and App Squad work updates.

The current runtime is a UI-first prototype backed by local mock data. Authentication, Supabase reads, live Rewards operations, and desktop Workspace synchronization are not implemented yet.

## Required Context

Read these files before architectural or implementation work:

1. `context/current-state.md`
2. `context/project-overview.md`
3. `context/architecture.md`
4. `context/code-standards.md`
5. `context/ui-context.md`
6. `context/progress-tracker.md`
7. `context/decision-log.md`
8. `context/ai-workflow-rules.md`

`current-state.md` is the runtime source of truth. `decision-log.md` records why important choices were made.

## Current Product Scope

Implemented with mock data:

- Home with Builder identity, level, Rewards balance, and followed Apps
- Rewards with balance, receive QR/ID presentation, and mock send form
- searchable Apps discovery
- App Squad detail with WIP, Committed Work, and Work History
- follow/unfollow presentation state
- three-tab bottom navigation
- official theBuilderPros logo, web favicon, and Android launcher icons

Not implemented:

- authentication or user sessions
- Supabase or other backend integration
- real QR generation, clipboard behavior, or Rewards transfer logic
- persistence across app restarts
- notifications
- loading/error/network states

Do not describe mocked behavior as production functionality.

## Domain Language

Use the Builder Workspace terminology:

- `Builder`
- `App` in Builder-facing UI; `Squad/App` when explaining the relationship
- `Work Item`, never Task
- `Committed`, `WIP`, and `Work History`
- `Rewards`, `Builder Rewards`, `Rewards Balance`; avoid wallet/Web3 wording

Work Items are independent records. App association belongs to `squad_work_item`; Builder participation belongs to link records such as `squad_builder` and `builder_work_item`.

## Architecture Rules

- Preserve Flutter + GetX.
- Preserve `BaseController`, `BaseView`, bindings, and centralized routes.
- Keep app-wide resources in `AppColors`, `AppDimens`, `AppString`, `AppImages`, and `AppTheme`.
- New backend access must go through typed services/repositories, not directly from widgets.
- Keep Supabase anon credentials public-client-safe and rely on RLS. Never ship service-role keys or account secrets.
- Prefer feature modules for new capabilities. The current all-in-one `profile` screen/controller is a prototype consolidation and should be split incrementally when logic work begins.
- Update context files whenever runtime scope, architecture, data contracts, or design rules materially change.

## Design Rules

- Use white cards/navigation over a neutral light background.
- Use solid black typography; do not introduce gray/dim text without explicit approval.
- Use orange for primary actions and focused emphasis.
- Use violet for selected navigation, supporting badges, focus states, and small brand accents.
- Do not add colored top strips to cards.
- The short page-title underline is approximately one-third width, mostly orange with a small violet ending.
- Preserve the official theBuilderPros logo and launcher artwork.

## Verification

Run Flutter commands independently from the project root:

```powershell
flutter pub get
flutter analyze
flutter test test\widget_test.dart --reporter expanded
```

For an Android artifact:

```powershell
flutter build apk --debug
```

Do not combine test and build commands into a single long shell invocation because it obscures failures and can trigger tool timeouts.

## Git

- Canonical repository: `https://github.com/theBuilderPros/TheFlutterBuilderProsApp.git`
- Primary branch: `main`
- Keep commits focused and keep the working tree clean before publishing.
- Never rewrite shared history or force-push unless the user explicitly requests it.
