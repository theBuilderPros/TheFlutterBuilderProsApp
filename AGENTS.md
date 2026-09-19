# AGENTS.md

## Purpose

This file defines the general working rules for the entire repository. Detailed product, architecture, design, and implementation guidance belongs in `context/` and should not be duplicated here.

## Context Files

Use the context files relevant to the task:

- `context/project-overview.md`: product purpose, scope, and domain language
- `context/current-state.md`: current runtime behavior and implementation status
- `context/architecture.md`: stack, structure, boundaries, and technical direction
- `context/code-standards.md`: Dart, Flutter, GetX, testing, and naming conventions
- `context/ui-context.md`: visual system and UI rules
- `context/decision-log.md`: important decisions and their rationale
- `context/progress-tracker.md`: active and completed work
- `context/ai-workflow-rules.md`: detailed implementation and documentation workflow

Read the files that apply before making meaningful changes. For broad architectural or product work, read all of them. Verify time-sensitive claims against the code and tests; when documentation and implementation disagree, call out the mismatch and update the relevant context file as part of the change.

## General Working Rules

- Keep changes focused on the requested outcome.
- Preserve existing architecture and conventions unless the task explicitly changes them.
- Fix root causes instead of layering workarounds.
- Keep presentation, state, domain logic, and data access appropriately separated.
- Reuse shared resources and abstractions before introducing new ones.
- Do not describe planned, mocked, or presentation-only behavior as implemented production functionality.
- Never commit credentials, secrets, privileged keys, recovery material, or private account data.
- Preserve unrelated user changes in the working tree.

## Documentation

Keep documentation synchronized with material changes:

- Runtime scope or implementation status: `context/current-state.md`
- Product scope or terminology: `context/project-overview.md`
- Architecture or data boundaries: `context/architecture.md`
- Coding or testing conventions: `context/code-standards.md`
- Visual rules: `context/ui-context.md`
- Durable decisions: `context/decision-log.md`
- Work progress: `context/progress-tracker.md`
- Contributor workflow: `context/ai-workflow-rules.md`

Avoid status reports, feature inventories, and duplicated context in this file.

## Verification

Run the checks relevant to the change from the repository root. Run them independently so failures are clear:

```powershell
flutter pub get
flutter analyze
flutter test
```

Format changed Dart files with `dart format`. Build platform artifacts when the task affects native configuration, packaging, or release output.

Report what was verified and any checks that could not be completed.

## Git

- Canonical repository: `https://github.com/theBuilderPros/TheFlutterBuilderProsApp.git`
- Primary branch: `main`
- Inspect the working tree and diff before staging.
- Keep commits focused and exclude unrelated changes.
- Do not rewrite shared history or force-push unless explicitly requested.
