# michifinanzas-ios

Native iOS codebase for MichiFinanzas.

The public product name is MichiFinanzas. Some technical identifiers still use
`SpendSage` or `spendsage` intentionally to preserve App Store, Cognito,
StoreKit, and installed TestFlight compatibility.

This repo starts as a SwiftUI, local-first migration track that runs in parallel with the existing Ionic + Capacitor app. The goal is to move the highest-impact B2C flows to native iOS without blocking the current production app.

## Scope of the first native track

- onboarding
- auth shell with Hosted UI-ready boundaries
- local guest mode
- local finance dashboard
- add-expense flow with on-device persistence
- native app shell with tabs for dashboard, expenses, insights, premium, and settings
- stubbed parity centers for support, legal, profile, rules, bills, accounts, scan, csv import, trophies, and brand gallery
- design system and app state foundation

## Why a separate repo

- native startup and interaction performance
- tighter control over iOS UX, navigation, animation, and accessibility
- easier long-term integration with Apple-first capabilities
- lower runtime complexity than a WebView-based shell for B2C growth loops

## Repo shape

- `SpendSage/Sources/App`: app entry point and root composition
- `SpendSage/Sources/Core`: app state, protocols, models, services
- `SpendSage/Sources/Features`: SwiftUI feature screens
- `SpendSage/Resources`: app resources
- `Docs`: migration strategy and handoff notes

## Generate the Xcode project

```bash
xcodegen generate
```

## Build for simulator

```bash
xcodebuild -project SpendSage.xcodeproj -scheme SpendSage -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

## Archive and upload to App Store Connect

```bash
bash scripts/app_store/archive_and_upload.sh internal
```

```bash
bash scripts/app_store/archive_and_upload.sh external
```

## Sync App Store Connect metadata

```bash
bash scripts/app_store/archive_and_upload.sh external
```

```bash
python3 scripts/app_store/testflight_promote.py --version 25 --wait
```

```bash
python3 scripts/app_store/app_store_connect_iris_sync.py --transport cookies --app-info --version --beta-app --beta-build --pricing --status
```

```bash
python3 scripts/app_store/app_store_connect_screenshots_sync.py --locales es-ES,en-US
```

Run the archive/upload first, then promote the matching build, and only then sync metadata that depends on the selected App Store Connect build id. The metadata sync covers App Store icon linkage through the promoted build, age rating, beta app text, beta build "what's new", pricing/localizations, review notes, review screenshots, product availability, and tax categories.

## Run tests

```bash
DEVICE_ID=$(xcrun simctl list devices available | grep 'iPhone' | head -n 1 | sed -E 's/.*\(([A-F0-9-]+)\).*/\1/')
xcodebuild test -project SpendSage.xcodeproj -scheme SpendSage -destination "platform=iOS Simulator,id=$DEVICE_ID" -derivedDataPath /tmp/michifinanzas-ios-dd CODE_SIGNING_ALLOWED=NO
```

## Current implementation notes

- email and create-account flows run through a native preview auth service with validation and loading states
- Apple and Google buttons are already gated by config and shaped for a future Cognito Hosted UI integration
- dashboard data is local-first and persisted in `UserDefaults`
- the native track is intentionally decoupled from backend availability for phase 1
- backend auth alignment remains Cognito-first so RevenueCat and entitlements can keep using Cognito `sub`

## Migration principle

Keep the web/hybrid app shipping. Migrate native iOS flow-by-flow behind explicit scope boundaries rather than rewriting everything at once.
