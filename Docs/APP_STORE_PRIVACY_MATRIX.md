# SpendSage App Privacy Matrix

Last updated: 2026-04-05

This document maps the current iOS implementation to App Store Connect `App Privacy` answers for the external release line.

## Tracking

- Tracks users across apps or websites: `No`
- Uses IDFA / App Tracking Transparency: `No`
- Advertising SDK active: `No`

## Data Collected

### Contact Info

- Data type: `Email Address`
- Collected by app or connected auth flow: `Yes`, if cloud auth is active for the submitted build
- Linked to the user: `Yes`
- Used for tracking: `No`
- Purpose: `App Functionality`

Reasoning:
- the app supports account-first authentication flows;
- email can be used in the auth flow and in the signed-in session state;
- no evidence of advertising or cross-app tracking exists in the current codebase.

## Data Not Declared As Collected for the Current Build

Do not declare the following as collected unless the backend behavior changes for the exact submitted build:

- Financial Info
  - expense history
  - budgets
  - account balances
  - bills
  - rules
- Photos or Videos
  - receipt images are selected or scanned locally for on-device processing
- Diagnostics
  - no third-party diagnostics SDK is active
- Location
  - no CoreLocation / geofence flow is active
- Purchases
  - no live StoreKit billing flow is currently active in the shipped external narrative
- Identifiers
  - no advertising identifiers or external analytics identifiers are active

## Permissions Used Locally

- Camera: `Yes`
  - purpose: receipt capture
- Photo Library Read: `Yes`
  - purpose: import receipt images
- Photo Library Add: `Yes`
  - purpose: save exported images/documents
- Notifications: `No active permission flow`
- Location: `No`

## Privacy Manifest

Current file:

- `/Users/rubenlazaro/Projects/spensage-ios/SpendSage/Resources/PrivacyInfo.xcprivacy`

Current declaration:

- `NSPrivacyTracking = false`
- `NSPrivacyAccessedAPICategoryUserDefaults` with reason `CA92.1`

Reasoning:
- the app uses `UserDefaults` / `@AppStorage` broadly for local settings, onboarding, guides, growth progress, and local finance state.

## External Submission Rule

If a future external build starts sending any of the following off device, update `App Privacy` before submission:

- ledger or financial history;
- support diagnostics sent automatically;
- receipt images uploaded to cloud OCR;
- push tokens;
- analytics events tied to users;
- family/shared-space account data.
