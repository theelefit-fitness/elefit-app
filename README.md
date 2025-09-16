# Elefit App

A Flutter-based e-commerce app for The Elefit, integrating with Shopify Storefront API and providing an in-app checkout experience with WebView and external payment app handoff.

## Features
- In-app product browsing powered by Shopify GraphQL (`lib/services/shopify_service.dart`).
- Cart and checkout flow with Shopify Cart + Checkout URL.
- Embedded checkout using `webview_flutter` with handling for payment apps (Google Pay/UPI/PayPal) in `lib/screens/webview_checkout_screen.dart`.
- Address capture and autofill during checkout.
- Caching for images, shimmer placeholders, and responsive UI.

## Tech Stack
- Flutter (Dart)
- Shopify Storefront GraphQL (via `graphql` package)
- WebView: `webview_flutter` (+ android/ios/web implementations)
- State management: `provider`
- Utilities: `http`, `connectivity_plus`, `device_info_plus`, `url_launcher`, `cached_network_image`, `google_fonts`, `intl`

## Project Structure
- `lib/`
  - `models/` — cart, address, and product-related models
  - `providers/` — app-wide providers (e.g., theme, location)
  - `screens/` — UI screens; checkout: `webview_checkout_screen.dart`
  - `services/` — Shopify integration: `shopify_service.dart`
- `assets/` — images and videos configured in `pubspec.yaml`
- `android/` — Android configuration and signing
- `ios/`, `macos/`, `windows/`, `linux/`, `web/` — platform targets

## Prerequisites
- Flutter SDK matching `environment` in `pubspec.yaml` (`sdk: '>=2.19.0 <4.0.0'`).
- Android Studio / Xcode as needed per platform.
- A Shopify store with Storefront API enabled and valid Storefront access token.

## Getting Started
1. Install dependencies:
   ```bash
   flutter pub get
   ```
2. Run on a device/emulator:
   ```bash
   flutter run
   ```

## Shopify Configuration
Shopify configuration is centralized in `lib/services/shopify_service.dart`:
```dart
static const String _storeUrl = 'theelefit.com';
static const String _storefrontAccessToken = '<YOUR_STOREFRONT_ACCESS_TOKEN>';
static const String _apiKey = '<OPTIONAL_ADMIN_API_KEY>';            // if used elsewhere
static const String _apiSecretKey = '<OPTIONAL_ADMIN_API_SECRET>';   // if used elsewhere
```
- Update `_storeUrl` and `_storefrontAccessToken` to your store.
- This app uses the Storefront API via GraphQL to create carts, add lines, and get a `checkoutUrl`.
- Security: avoid committing real secrets. Consider injecting values via CI or a private config method.

## Android Configuration
- Package and app ID: set to `com.theelefit.app` in `android/app/build.gradle.kts` (`namespace` and `applicationId`).
- Ensure the Kotlin package in `MainActivity.kt` is `package com.theelefit.app` (already set).
- Note: Align the Kotlin source path with the package if you refactor packages (expected path: `android/app/src/main/kotlin/com/theelefit/app/MainActivity.kt`).
- Min SDK: `21`.

### Signing (Release)
`build.gradle.kts` reads signing from either `android/key.properties` or `android/app/key.properties`:
```
storeFile=<relative path to keystore from android/>
storePassword=<password>
keyAlias=<alias>
keyPassword=<password>
```
Ensure the keystore file exists and paths are correct.

## Build
- Android APK (release):
  ```bash
  flutter build apk --release
  ```
- Android App Bundle (Play Store):
  ```bash
  flutter build appbundle --release
  ```
- iOS (from macOS):
  ```bash
  flutter build ios --release
  ```
- Web:
  ```bash
  flutter build web
  ```

## Checkout and Payments
The checkout flow loads Shopify `checkoutUrl` inside a WebView (`WebViewCheckoutScreen`). Highlights:
- JavaScript injection auto-fills address data (from `AddressModel`).
- Navigation delegate allows common payment and Shopify domains.
- External payment schemes/URLs (e.g., `googlepay://`, `upi://`, PayPal) are detected and launched with `url_launcher`.
- Connectivity checks and friendly error messages help users if the checkout is blocked by network or requires VPN.

### Known Considerations
- Some payment providers require the native app (e.g., Google Pay/UPI). The WebView will hand off to the external app when needed.
- Network restrictions (corporate/Wi‑Fi) may block Shopify/payment domains. The app suggests switching networks or using a VPN when applicable.

## Troubleshooting
- Checkout not loading / network errors:
  - Verify internet and try a different network or VPN.
  - Confirm the `checkoutUrl` is reachable (HTTP 200/3xx) from the device.
- Payment app not opening:
  - Ensure the target app is installed (e.g., Google Pay). The app offers Play Store fallback.
- Build issues (Android):
  - Confirm `applicationId` and Kotlin package align with folder structure.
  - Ensure JDK 11 compatibility is configured (already set in Gradle script).
- Shopify API issues:
  - Validate the Storefront Access Token and API version in `ShopifyService`.
  - Check that product variant IDs use `gid://shopify/ProductVariant/<id>` format (handled in code).

## Assets
Images and videos declared in `pubspec.yaml` under `flutter/assets`:
- `assets/images/` (including `elefit_logo.png`, `LogoIcon.png`)
- `assets/videos/video*.mp4`

## Security Notes
- Do not commit real Shopify secrets. If present during development, rotate them and move to a secure configuration strategy before release.

## License
Proprietary — The Elefit. All rights reserved.
