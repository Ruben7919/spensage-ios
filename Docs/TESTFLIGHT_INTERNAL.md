# SpendSage Internal TestFlight Notes

Last updated: 2026-04-03

## Build

- App: `SpendSage`
- Version: `1.0`
- Build: `7`
- Bundle ID: `com.spendsage.ai`
- Team ID: `YU855NB22W`

## Upload Status

- Archive completed successfully from `SpendSage.xcodeproj`
- Upload completed successfully to App Store Connect
- TestFlight scope: internal testing only
- Current state: waiting for App Store Connect processing to finish

## Archive Paths

- Archive: `/Users/rubenlazaro/Projects/spensage-ios/build/SpendSage-1.0-7.xcarchive`
- Export options: `/Users/rubenlazaro/Projects/spensage-ios/build/ExportOptions-TestFlight-Internal.plist`

## Internal QA Focus

1. Validate the simplified auth flow, especially email-first entry plus Apple/Google login buttons.
2. Validate the main B2C loop: onboarding, dashboard, quick expense capture, receipt draft, and premium messaging.
3. Validate secondary tools on smaller iPhones: accounts, bills, CSV import, budget wizard, help, and support.
4. Confirm Spanish-first copy is consistent enough for internal review and note any remaining mixed-language strings.
5. Confirm the app never implies live backend, OCR, billing, or sync capabilities that are not active yet.

## Known Pre-External-Beta Gaps

- Secondary surfaces still depend on prompt-based art in `Rules`, `Profile`, `Help`, and `Advanced`.
- `Receipt Scan` still needs one more honesty pass to keep the non-OCR behavior explicit.
- A deeper long-scroll visual QA pass is still recommended after internal feedback.
