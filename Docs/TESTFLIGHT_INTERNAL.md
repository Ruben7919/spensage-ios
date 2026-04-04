# SpendSage Internal TestFlight Notes

Last updated: 2026-04-04

## Build

- App: `SpendSage`
- Version: `1.0`
- Build: `8`
- Bundle ID: `com.spendsage.ai`
- Team ID: `YU855NB22W`

## Upload Status

- Archive completed successfully from `SpendSage.xcodeproj`
- Upload completed successfully to App Store Connect
- TestFlight scope: internal testing only
- Current state: waiting for App Store Connect processing to finish
- Notes: build `8` includes the Xcode 26 universal `AppIcon` with `Any`, `Dark`, and `Tinted` variants plus refreshed launch/loading artwork

## Archive Paths

- Archive: `/Users/rubenlazaro/Projects/spensage-ios/build/SpendSage-1.0-8.xcarchive`
- Export options: `/Users/rubenlazaro/Projects/spensage-ios/build/ExportOptions-TestFlight-Internal.plist`

## Internal QA Focus

1. Validate the simplified auth flow, especially email-first entry plus Apple/Google login buttons.
2. Validate the main B2C loop: onboarding, dashboard, quick expense capture, receipt draft, and premium messaging.
3. Validate secondary tools on smaller iPhones: accounts, bills, CSV import, budget wizard, help, and support.
4. Confirm Spanish-first copy is consistent enough for internal review and note any remaining mixed-language strings.
5. Confirm the app never implies live backend, billing, or sync capabilities that are not active yet beyond the current local/OCR scope.
6. Validate home screen icon rendering under default, dark, and tinted icon appearances on an iOS 26 device.

## Known Pre-External-Beta Gaps

- Home screen icon variants should still be checked on physical hardware under `Any`, `Dark`, and `Tinted` appearances.
- `Receipt Scan` still needs real-device validation against varied receipts before external beta.
- A deeper long-scroll visual QA pass is still recommended after internal feedback.
