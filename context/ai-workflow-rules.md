# AI Workflow Rules

## Context Routing

Always read `AGENTS.md`, then read the context files relevant to the task:

- Product purpose, scope, or terminology: `project-overview.md`
- Current implementation or capability claims: `current-state.md`
- Structure, dependencies, or technical boundaries: `architecture.md`
- Dart, Flutter, GetX, naming, or testing conventions: `code-standards.md`
- Visual or interaction design: `ui-context.md`
- Prior decisions and rationale: `decision-log.md`
- Completed work or active backlog: `progress-tracker.md`

Read all context files for broad product, architecture, or cross-cutting work. Verify volatile facts against the code and tests.

## Scope Discipline

- Keep work within the requested scope.
- Do not introduce unrelated training or product narratives.
- Do not claim authentication, backend integration, persistence, notifications, or real Rewards behavior unless implemented and verified.
- A UI request does not authorize backend or security-sensitive implementation.
- Introduce typed service boundaries for data or integration work instead of embedding calls in widgets.
- Preserve Builder Workspace domain terminology.

## Implementation

- Preserve Flutter, GetX, base abstractions, bindings, centralized routes, and shared resources unless the task explicitly changes the architecture.
- Put new capabilities in focused feature modules.
- Do not expand an already broad feature with unrelated production logic.
- Keep credentials and secrets out of source control and client UI.
- Update the context file that owns any implementation truth changed by the work.

## Verification

Run relevant checks independently. The default full-project checks are:

```powershell
flutter pub get
flutter analyze
flutter test
```

Use targeted tests while diagnosing a failure, but run the full relevant suite before reporting completion. Use `flutter build apk --debug` when Android packaging or native resources are affected.

If a command times out, rerun it independently. Do not report a timeout as a test failure without test output.

## Documentation

Keep each fact in its owning context file instead of copying it across several documents. Use links when another document needs the information.

Documentation must distinguish among:

- intended product behavior
- implemented runtime behavior
- mock or presentation behavior
- planned work
- explicit product boundaries

## Git

- Inspect status and diff before staging.
- Keep commits focused.
- Do not publish unrelated user changes.
- Do not rewrite shared history or force-push without explicit instruction.
