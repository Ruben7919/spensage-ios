# Internal Beta Plan Testing

Updated: 2026-04-07

## Goal

Allow authenticated internal QA to validate `Free`, `Pro`, and `Family` behavior against the `dev` backend.

## Strategy

- Internal QA can still use the `dev` backend.
- Testers authenticate with Cognito, Apple, Google, or email/password.
- The backend still exposes a non-production-only override route:
  - `POST /billing/dev-tester-plan`
- Release builds now hide the override UI by default.
- For TestFlight-style validation, prefer native StoreKit sandbox purchases and restore flows.
- Keep the tester-plan override for local/dev-only QA or explicitly internal builds.

## Supported tester plans

- `free`
- `personal` (`Pro` in the iOS UI)
- `family`
- `enterprise`

The backend also accepts `pro` as an alias and normalizes it to `personal`.

## Current validation

- Verified on 2026-04-07 against `https://cz2vxbcze4.execute-api.us-east-1.amazonaws.com/dev/`.
- Authenticated smoke user successfully loaded `/me/finance-bootstrap`.
- Authenticated smoke user successfully persisted `/me/native-profile`.
- Authenticated smoke user successfully created an expense with `locationLabel`.
- Authenticated tester-plan override successfully returned premium entitlements in `dev`.

## Guardrails

- This route is disabled in `prod`.
- External beta and App Store review should use the real StoreKit purchase surfaces.
- This is a QA-only billing shortcut, not a production monetization path.
