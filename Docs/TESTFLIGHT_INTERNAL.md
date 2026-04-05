# SpendSage Internal TestFlight Notes

Last updated: 2026-04-05

## Build

- App: `SpendSage`
- Version: `1.0`
- Build: `10`
- Bundle ID: `com.spendsage.ai`
- Team ID: `YU855NB22W`

## Upload Status

- Archive completed successfully from `SpendSage.xcodeproj`
- Upload completed successfully to App Store Connect
- TestFlight scope: internal testing only
- Current state: waiting for App Store Connect processing to finish
- Notes: build `10` includes the new three-mascot peeking `AppIcon` with `Any`, `Dark`, and `Tinted` variants, the final full-route visual QA repair pass, a lighter legal/profile/advanced navigation pass, a stronger celebration modal, and receipt scan actions surfaced directly in the first fold

## Archive Paths

- Archive: `/Users/rubenlazaro/Projects/spensage-ios/build/SpendSage-1.0-10.xcarchive`
- Export options: `/Users/rubenlazaro/Projects/spensage-ios/build/ExportOptions-TestFlight-Internal.plist`
- Upload executed directly via `xcodebuild -exportArchive ... -destination upload` with no persisted export bundle kept on disk

## Internal QA Focus

1. Validate the new three-character icon on device under default, dark, and tinted icon appearances on iOS 26.
2. Validate the simplified auth flow, especially email-first entry plus Apple/Google login buttons.
3. Validate the main B2C loop: onboarding, dashboard, quick expense capture, receipt draft, celebration overlay, and premium messaging.
4. Validate secondary tools on smaller iPhones: accounts, bills, CSV import, budget wizard, help, support, legal, profile, and advanced settings.
5. Confirm Spanish-first copy is consistent enough for internal review and note any remaining mixed-language strings below the top fold.
6. Confirm the app never implies live backend, billing, sync, or notifications that are not active yet beyond the current local/OCR scope.

## Known Pre-External-Beta Gaps

- Home screen icon variants should still be checked on physical hardware under `Any`, `Dark`, and `Tinted` appearances.
- `Receipt Scan` still needs real-device validation against varied receipts before external beta.
- Internal feedback should still drive one more device-level polish pass before opening the app to a wider beta audience.
