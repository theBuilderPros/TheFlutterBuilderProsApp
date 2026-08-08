# Architecture Context

## Stack

| Layer | Technology | Current role |
| --- | --- | --- |
| UI framework | Flutter / Dart `^3.9.2` | Cross-platform mobile and desktop-capable UI |
| Design system | Material 3 | Theme, navigation, controls, typography |
| State and DI | GetX `^4.7.2` | Reactive UI state, bindings, routing |
| Icons | Material Icons | Current icon system |
| Testing | `flutter_test` | App-level widget smoke test |
| Data source | In-memory mock objects | Temporary UI prototype data |
| Mini app runtime | WebView + local asset server | Bundled mini app host demo |

There is currently no SVG dependency, auth package, Supabase client, HTTP client, database, or local persistence layer. `webview_flutter` is present for the bundled mini app host demo.

## Startup and Routing

1. `lib/main.dart` starts the app.
2. `lib/main_app.dart` creates `GetMaterialApp`, applies `AppTheme.lightTheme`, initial binding, and route table.
3. `AppPages` registers one route: `Routes.profileScreen`.
4. `ProfileBinding` registers `ProfileController` with `Get.lazyPut(..., fenix: true)`.
5. `ProfileScreen` extends `BaseView<ProfileController>` and renders the main mobile shell.
6. `MiniAppHostBinding` registers `MiniAppHostController` for `Routes.miniAppHostScreen`.

The three bottom tabs are internal reactive state, not separate GetX routes. App Detail is also selected state inside the shell.
The Mini App Host is a separate GetX route opened from the Apps tab.

## Current Feature Boundary

```text
lib/app/features/profile/
├── binding/profile_binding.dart
├── controller/profile_controller.dart
└── screen/profile_screen.dart

lib/app/features/mini_app_host/
├── binding/mini_app_host_binding.dart
├── controller/mini_app_host_controller.dart
└── screen/mini_app_host_screen.dart
```

Despite the directory name, this feature presently contains the whole prototype:

- `_Home`
- `_Rewards`
- `_Apps`
- `_SquadDetail`
- shared private presentation widgets
- mock models and records in `ProfileController`

This consolidation reflects current code, but it is not the desired long-term boundary. When real logic begins, extract focused feature modules without rewriting the working shell all at once.

Recommended direction:

```text
lib/app/features/home/
lib/app/features/rewards/
lib/app/features/apps/
lib/app/features/profile/
lib/app/data/ or lib/app/services/
```

The mini app host uses `lib/app/services/mini_app_asset_server.dart` to serve `assets/mini_app` through a phone-local loopback URL. The bundled Vite mini app source lives in `mini_apps/quickpay_pass`.

## Reactive State

`ProfileController` owns:

- `tabIndex`
- `rewardsMode`
- `selectedSquad`
- `followedIds`
- `search`
- mock Builder, Squad, and Work Item lists

Views observe state with `Obx`. Current state lasts only for the process lifetime.

## Current Mock Types

- `BuilderProfile`: name, email, level
- `Squad`: id, name, description, status, presentation color value
- `WorkItem`: squad id, title, outcome, state, cycle, week, week label

These are simplified UI models. They are not complete persistence entities and should be replaced or adapted through typed DTO/domain mappings when the backend is connected.

## Future Data Boundary

Widgets must not call Supabase directly. Add service/repository interfaces for:

- authentication/session
- Builder profile
- Apps and follow relationships
- App Work Items
- Rewards balance/history/send/receive

The intended shared backend is Supabase Auth + Postgres + RLS. Both Electron and Flutter clients should use public anon credentials and RLS. Service-role keys and secret account material must never ship in this app.

## Resource Boundaries

- `AppColors`: brand and semantic colors
- `AppTheme`: Material component and typography themes
- `AppDimens`: reusable dimensions
- `AppString`: app-level strings
- `AppImages`: asset paths
- `assets/images/`: official source logo
- native platform folders: launcher/application branding

## Known Technical Debt

- `ProfileScreen` and `ProfileController` are too broad.
- Many private widgets, strings, and dimensions remain inline in the prototype screen.
- Mock models are coupled to UI state.
- Real QR, clipboard, forms, validation, loading, and error handling are absent.
- Test coverage currently verifies only initial Home rendering.

Address these incrementally during logic integration; do not claim they are already resolved.
