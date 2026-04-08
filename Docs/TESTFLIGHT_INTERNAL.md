# SpendSage Internal TestFlight Notes

Last updated: 2026-04-08

## Build

- App: `SpendSage`
- Version: `1.0`
- Build: `22`
- Bundle ID: `com.spendsage.ai`
- Team ID: `YU855NB22W`

## Upload Status

- Archive completed successfully from `SpendSage.xcodeproj`
- Upload completed successfully to App Store Connect
- Upload mode: external-capable App Store eligible build
- Internal availability: automatic after processing for internal testers
- External availability: attached to the configured external beta group
- Current state: `WAITING_FOR_REVIEW` for external TestFlight beta review
- Notes: build `22` is the authenticated beta line with cloud finance sync, family shared spaces and invites, native StoreKit subscriptions, verified physical iPhone push delivery, and first-party reliability telemetry.

## Archive Paths

- Archive: `/Users/rubenlazaro/Projects/spensage-ios/build/SpendSage-1.0-22.xcarchive`
- Export options: `/Users/rubenlazaro/Projects/spensage-ios/build/ExportOptions-TestFlight-External.plist`
- Upload executed via `/Users/rubenlazaro/Projects/spensage-ios/scripts/app_store/archive_and_upload.sh external`
- App Store Connect build id: `578d54d2-918e-4ad4-bd1d-6f5cb352065f`

## Internal QA Focus

1. Validate the new three-character icon on device under default, dark, and tinted icon appearances on iOS 26.
2. Validate remembered-device behavior: Apple/Google/email should reopen the saved account and request Face ID or device passcode instead of forcing a fresh social login.
3. Validate the simplified auth flow, especially email-first entry, Apple/Google consent, the one-time short profile-completion screen after social login, and the updated icon/logo spacing on provider sheets.
4. Validate the main authenticated loop: onboarding, login, dashboard, expense capture, receipt scan, insights, cloud sync, and shared-space browsing.
5. Validate native StoreKit purchase, restore, and manage-subscription surfaces from Premium.
6. Validate push revalidation and manual test-push from Settings on physical iPhone.
7. Confirm Spanish-first copy is consistent enough for beta review and note remaining mixed-language strings below the top fold.

## Known Pre-External-Beta Gaps

- Home screen icon variants should still be checked on more physical devices under `Any`, `Dark`, and `Tinted` appearances.
- Android / FCM and RevenueCat server reconciliation remain out of scope for this iOS beta line.
- A dedicated `beta` backend is still preferable before any broader public launch beyond this small TestFlight cohort.
