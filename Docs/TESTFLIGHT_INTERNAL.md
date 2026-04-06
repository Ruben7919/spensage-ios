# SpendSage Internal TestFlight Notes

Last updated: 2026-04-05

## Build

- App: `SpendSage`
- Version: `1.0`
- Build: `15`
- Bundle ID: `com.spendsage.ai`
- Team ID: `YU855NB22W`

## Upload Status

- Archive completed successfully from `SpendSage.xcodeproj`
- Upload completed successfully to App Store Connect
- TestFlight scope: internal testing only
- Current state: waiting for App Store Connect processing to finish
- Notes: build `15` keeps the Cognito Hosted UI DEV alignment and adds a stronger spending-entry pass: the tab shell now lives as a real bottom block instead of floating over content, manual expense capture localizes category labels, subscriptions can store recurrence cadence plus renewal date and optional auto-recording, pasted email or online purchase summaries can prefill a draft, and trophy history cards no longer collapse badge text vertically.

## Archive Paths

- Archive: `/Users/rubenlazaro/Projects/spensage-ios/build/SpendSage-1.0-15.xcarchive`
- Export options: `/Users/rubenlazaro/Projects/spensage-ios/build/ExportOptions-TestFlight-Internal.plist`
- Upload executed directly via `xcodebuild -exportArchive ... -destination upload` with no persisted export bundle kept on disk

## Internal QA Focus

1. Validate the new three-character icon on device under default, dark, and tinted icon appearances on iOS 26.
2. Validate remembered-device behavior: Apple/Google/email should reopen the saved account and request Face ID or device passcode instead of forcing a fresh social login.
3. Validate the simplified auth flow, especially email-first entry, Apple/Google consent, the one-time short profile-completion screen after social login, and the updated icon/logo spacing on provider sheets.
4. Validate the main B2C loop: onboarding, dashboard, direct-to-camera receipt capture, editable receipt draft, full-height manual expense registration, pasted email import, subscription recurrence setup, celebration overlay, and premium messaging.
5. Validate secondary tools on smaller iPhones: accounts, bills, CSV import, budget wizard, help, support, legal, profile, and advanced settings.
6. Confirm Spanish-first copy is consistent enough for internal review and note any remaining mixed-language strings below the top fold.
7. Confirm the app never implies live backend, billing, sync, or notifications that are not active yet beyond the current local/OCR scope.

## Known Pre-External-Beta Gaps

- Home screen icon variants should still be checked on physical hardware under `Any`, `Dark`, and `Tinted` appearances.
- `Receipt Scan` still needs real-device validation against varied receipts before external beta.
- Internal feedback should still drive one more device-level polish pass before opening the app to a wider beta audience.
