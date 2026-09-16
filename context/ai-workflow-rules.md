# AI Workflow Rules

## Required Reading

Before meaningful changes, read:

1. `AGENTS.md`
2. `context/current-state.md`
3. `context/project-overview.md`
4. `context/architecture.md`
5. `context/code-standards.md`
6. `context/ui-context.md`
7. `context/progress-tracker.md`
8. `context/decision-log.md`

Use current state as implementation truth and verify it against code when facts may have drifted.

## Scope Discipline

- Do not restore the old Week 1/Week 2 training narrative.
- Do not claim Google Sign-In, Classroom, Supabase, persistence, or real Rewards behavior unless implemented and verified.
- UI-only requests do not authorize backend or security-sensitive logic.
- Logic requests should introduce typed service boundaries rather than embedding calls in widgets.
- Preserve Builder Workspace domain terminology.

## Implementation Rules

- Preserve Flutter, GetX, base abstractions, bindings, centralized routes, and resources unless explicitly changing architecture.
- New capabilities should use focused feature files/modules.
- Do not expand the already broad prototype screen/controller with unrelated production logic.
- Keep credentials and secrets out of source control and client UI.
- Update context when implementation truth changes.

## UI Rules

- Maintain white surfaces, neutral background, black text, orange primary actions, and restrained violet support.
- Do not add colored strips to cards.
- Do not use gray/dim typography without explicit user direction.
- Preserve the short mixed-color page-title underline and official logo assets.
- Prefer centralized tokens over new hardcoded design values.

## Verification Rules

Run relevant commands independently:

```powershell
flutter pub get
flutter analyze
flutter test test\widget_test.dart --reporter expanded
```

Use `flutter build apk --debug` only when an Android artifact or native-resource verification is relevant.

If a command times out, do not report it as a test failure without test output. Re-run the specific command independently and report the actual result.

## Documentation Rules

Documentation must distinguish:

- implemented runtime behavior
- mock/presentation behavior
- planned integration
- explicit non-goals

When changing architecture, product scope, design rules, data contracts, or verification workflow, synchronize the relevant context files in the same change.

## Git Rules

- canonical remote: `https://github.com/theBuilderPros/TheFlutterBuilderProsApp.git`
- primary branch: `main`
- inspect status/diff before staging
- keep commits focused
- do not force-push or rewrite shared history without explicit instruction
- do not publish unrelated user changes
