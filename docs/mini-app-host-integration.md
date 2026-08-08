# Mini App Host Integration

## Scope

This branch adds a bundled WebView mini app host to theBuilderStudio as a demo capability.

Implemented:

- GetX route, binding, controller, and screen for `MiniAppHostScreen`
- local Flutter asset server for bundled mini app files
- WebView loading from `http://127.0.0.1:<dynamic-port>`
- JavaScript bridge from mini app to Flutter host
- mock host actions for Builder profile, Rewards action, Rewards refresh, and close
- Vite mini app source copied under `mini_apps/quickpay_pass`

Not implemented:

- remote mini app registry
- signed mini app package validation
- backend Rewards transaction
- Supabase integration
- production payment or custody flow

## Branch Workflow

Recommended real-life flow:

```text
main
  -> feature/mini-app-host
  -> pull request review
  -> merge into main
  -> release merge main into production when approved
```

Do not push directly to `production`. A production branch should receive reviewed code only.

## Flutter Files

```text
lib/app/features/mini_app_host/
├── binding/mini_app_host_binding.dart
├── controller/mini_app_host_controller.dart
└── screen/mini_app_host_screen.dart

lib/app/services/mini_app_asset_server.dart
```

Route registration:

```text
lib/app/constant/routing/app_route.dart
lib/app/constant/routing/app_pages.dart
```

Entry point from the current prototype shell:

```text
lib/app/features/profile/screen/profile_screen.dart
```

The Apps tab includes an `Open Mini App Host` card that navigates to the new route.

## Mini App Files

Bundled runtime assets:

```text
assets/mini_app/
├── index.html
├── miniapp.json
└── assets/*.js, *.css
```

Source mini app:

```text
mini_apps/quickpay_pass/
├── src/
├── public/
├── package.json
├── package-lock.json
├── vite.config.js
└── capacitor.config.ts
```

## pubspec Settings

`pubspec.yaml` includes:

```yaml
dependencies:
  webview_flutter: ^4.14.1

flutter:
  assets:
    - assets/images/
    - assets/mini_app/
    - assets/mini_app/assets/
```

## Android Settings

`android/app/src/main/AndroidManifest.xml` includes:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

and:

```xml
android:usesCleartextTraffic="true"
```

Reason: the embedded WebView loads the mini app from a local phone URL:

```text
http://127.0.0.1:<dynamic-port>
```

This is a loopback address inside the app runtime. It is not a public server.

## Local Hosting Flow

```text
Flutter route opens
  -> MiniAppHostController starts MiniAppAssetServer
  -> server binds to 127.0.0.1 and a free port
  -> WebViewController loads that local URL
  -> server maps URL paths to Flutter assets
  -> WebView renders the mini app
```

Example:

```text
GET /
  -> assets/mini_app/index.html

GET /assets/index-abc.js
  -> assets/mini_app/assets/index-abc.js
```

## JavaScript Bridge Flow

Flutter injects:

```js
window.SuperAppBridge.call(action, payload)
```

The mini app calls:

```js
window.SuperAppBridge.call('requestPayment', {
  amount: 12500,
  currency: 'MMK'
});
```

Flutter receives the message through:

```text
JavaScriptChannel('FlutterHost')
```

Then `MiniAppHostController` returns mock JSON to the mini app.

## Endpoint Policy

Do not place real API credentials or service-role keys in the mini app.

Recommended production direction:

```text
Mini app JS
  -> asks Flutter bridge
  -> Flutter calls typed service/repository
  -> service talks to Supabase/API with public-client-safe auth
  -> Flutter returns allowed result to JS
```

`miniapp.json` should describe mini app metadata:

- id
- name
- version
- permissions
- entry file

Real backend URLs should live in a typed Flutter config/service layer, not inside widgets.

## Verification

Run independently from repo root:

```powershell
flutter pub get
flutter analyze
flutter test test\widget_test.dart --reporter expanded
```

Mini app source preview:

```powershell
cd mini_apps\quickpay_pass
npm install
npm run build
```

After building the Vite app, copy `dist` contents into:

```text
assets/mini_app/
```
