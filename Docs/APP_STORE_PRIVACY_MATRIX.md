# SpendSage App Privacy Matrix

Last updated: 2026-04-08

This document maps the current native iOS build to App Store Connect `App Privacy` answers.

Reference used for the interpretation of `collect` and optional disclosure:

- [Apple App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/)

## Tracking

- Tracks users across apps or websites: `No`
- Uses IDFA / App Tracking Transparency: `No`
- Advertising SDK active: `No`

## Data Collected

Declare the following conservatively for the current authenticated beta build.

### Contact Info

- `Name`
  - collected: `Yes`
  - linked to the user: `Yes`
  - used for tracking: `No`
  - purpose: `App Functionality`, `Product Personalization`
- `Email Address`
  - collected: `Yes`
  - linked to the user: `Yes`
  - used for tracking: `No`
  - purpose: `App Functionality`

Reasoning:

- the app requires account-based authentication;
- the native profile can be synced to backend and includes user identity fields.

### Financial Info

- `Other Financial Info`
  - collected: `Yes`
  - linked to the user: `Yes`
  - used for tracking: `No`
  - purpose: `App Functionality`

Reasoning:

- authenticated sessions can sync expenses, budgets, accounts, bills, rules, and monthly profile values to the backend;
- Apple’s guidance treats off-device storage beyond the real-time request window as collected data.

### Location

- `Coarse Location`
  - collected: `Yes`, conservatively
  - linked to the user: `Yes`
  - used for tracking: `No`
  - purpose: `App Functionality`

Reasoning:

- the app can request current location while in use to label an expense;
- the app does not send raw latitude/longitude, but it can derive and persist a human-readable place label that may sync off device;
- Apple states that derived data sent off device should be considered separately.

### Identifiers

- `User ID`
  - collected: `Yes`
  - linked to the user: `Yes`
  - used for tracking: `No`
  - purpose: `App Functionality`
- `Device ID`
  - collected: `Yes`, conservatively
  - linked to the user: `Yes`
  - used for tracking: `No`
  - purpose: `App Functionality`

Reasoning:

- Cognito account identifiers are stored and used server-side;
- APNs device tokens are uploaded to backend for push routing, so they should be treated conservatively as a device-level identifier.

### Usage Data

- `Product Interaction`
  - collected: `Yes`
  - linked to the user: `Yes`
  - used for tracking: `No`
  - purpose: `Analytics`, `App Functionality`

Reasoning:

- the app now batches first-party product events to `/me/telemetry` once the user is authenticated;
- the event stream is used for beta reliability and product-flow validation, not for third-party ad targeting.

### Diagnostics

- `Crash Data`
  - collected: `Yes`
  - linked to the user: `Yes`, conservatively
  - used for tracking: `No`
  - purpose: `App Functionality`, `Analytics`
- `Performance Data`
  - collected: `Yes`
  - linked to the user: `Yes`, conservatively
  - used for tracking: `No`
  - purpose: `App Functionality`, `Analytics`

Reasoning:

- the native app now captures first-party MetricKit diagnostics and forwards them to the authenticated backend telemetry endpoint;
- this is used for release-health visibility and failure analysis without a third-party crash SDK.

## Data Not Declared for the Current Build

Do not declare the following unless the exact submitted build changes:

- `Payment Info`
  - StoreKit payment processing is handled by Apple; the app does not receive raw payment card or bank details.
- `Purchase History`
  - the current build has native StoreKit surfaces, but purchase history is not currently collected by your backend or a third-party entitlement service.
- `Photos or Videos`
  - receipt images are selected or scanned locally for on-device processing.
- `Precise Location`
  - the app does not intentionally retain or sync latitude/longitude coordinates.

## Permissions Used in the Current Build

- Camera: `Yes`
  - purpose: receipt capture
- Photo Library Read: `Yes`
  - purpose: import receipt images
- Photo Library Add: `Yes`
  - purpose: save exported images and documents
- Notifications: `Yes, optional`
  - purpose: budget alerts and device-level push validation when the user explicitly enables notifications
- Location: `Yes, optional`
  - purpose: label an expense with the current place when the user explicitly requests it
- Calendar: `Yes, optional`
  - purpose: create recurring bill reminders when the user explicitly syncs them

## Privacy Manifest

Current file:

- `/Users/rubenlazaro/Projects/spensage-ios/SpendSage/Resources/PrivacyInfo.xcprivacy`

Current declaration:

- `NSPrivacyTracking = false`
- `NSPrivacyAccessedAPICategoryUserDefaults` with reason `CA92.1`

## External Submission Rule

Before each external TestFlight or App Store submission:

- verify the exact build/backend pairing;
- re-check whether push tokens are stored off device in that build;
- re-check whether authenticated finance sync is enabled in that build;
- if analytics or crash telemetry become active, update App Privacy before submission.
- for the current beta cut, analytics and crash telemetry are active first-party, so the App Privacy answers must reflect them.
