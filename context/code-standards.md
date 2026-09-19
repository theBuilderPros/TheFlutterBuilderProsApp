# Code Standards

## General

- Keep changes focused and preserve working behavior.
- Use explicit Dart types and avoid `dynamic` unless an external boundary requires it.
- Prefer immutable models and `const` constructors.
- Keep presentation, state, domain logic, and data access separate.
- Fix root causes instead of layering workarounds.
- Run `dart format` on changed Dart files.
- Keep `flutter analyze` clean; do not suppress lints without justification.

## Flutter and GetX

- Controllers extend `BaseController`.
- Route-level screens extend `BaseView<T>` and implement `buildView()`.
- Register feature controllers in a `Bindings` class.
- Use `Obx` for reactive presentation and keep mutations in controllers or services.
- Do not place backend calls, credentials, or persistence logic in widgets.
- Use centralized route names instead of string literals.
- Keep one route-level screen implementation per file.
- Group larger screen sets by user journey and use export-only barrel files where they simplify route imports.

## Feature Organization

Use focused feature modules for new production logic:

```text
lib/app/features/{feature}/binding/
lib/app/features/{feature}/controller/
lib/app/features/{feature}/screen/
lib/app/features/{feature}/widget/
```

Feature-owned widgets belong in that feature's `widget/` folder. Use `lib/app/widget/` only when a component is shared across unrelated features. Shared services and repositories belong in a clearly named data or services layer.

## Resources

- Use `AppColors` and `AppTheme` for shared colors and component styling.
- Use `AppDimens` for repeated dimensions.
- Move repeated user-facing strings to `AppString`.
- Reference asset paths through `AppImages`.
- Use `Theme.of(context).textTheme` for standard text roles.
- Centralize reused semantic status colors.

Detailed visual direction belongs in `ui-context.md`; domain terminology belongs in `project-overview.md`.

## Data and Security

- Map backend snake_case records to typed Dart models.
- Use repositories or services as the UI's data boundary.
- Never commit API secrets, service-role keys, seeds, recovery phrases, or private account material.
- Enforce authorization at the selected backend boundary, not through client-side hiding.

## Testing

- Unit and widget tests live under `test/`.
- End-to-end tests belong under `integration_test/`.
- Add or update tests when behavior changes.
- Cover state transitions, filtering, empty states, navigation, and failures as those behaviors are introduced.

Run the default checks independently:

```powershell
flutter analyze
flutter test
```

Target a specific test file only while diagnosing or iterating; use the full suite for final verification.
