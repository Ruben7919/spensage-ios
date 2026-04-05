# SpendSage iOS Feature Checklist

Last updated: 2026-04-04

## Goal

Ship a B2C iOS app that feels simple, powerful, trustworthy, and ready for backend alignment without misleading the user about capabilities that are not live yet.

## Status Legend

- `[x]` done in the current native app
- `[-]` in progress or partially implemented
- `[ ]` pending
- `[>]` planned after backend/store integration

## Must-Have

### Product Foundations

- [x] Native app shell with reusable components
- [x] Tab navigation for `Inicio`, `Gastos`, `Scan`, `Análisis`, `Ajustes`
- [x] Mascot system integrated across the main surfaces
- [x] Spanish-first copy consistency across the core screens and touched finance/support routes
- [x] Currency setting honored across all user-facing financial surfaces
- [-] Final pre-TestFlight visual QA across all main and secondary routes
- [x] Root tabs now use simpler inline navigation chrome instead of large-title duplication
- [x] Internal TestFlight archive and upload

### Onboarding and Auth

- [x] Short onboarding focused on first value
- [x] Simplified account-first login box with Apple/Google and clear links
- [x] Account creation and recovery routes kept inside the same auth surface
- [-] Auth/recovery copy aligned with real backend readiness
- [>] Real cloud auth completion, verification, and recovery

### Local Finance Core

- [x] Local ledger persistence
- [x] Manual expense capture
- [x] Budget setup and local dashboard
- [x] Accounts, bills, and rules management
- [x] Smart autofill from repeated merchants
- [x] Assisted receipt draft flow without blocking on OCR
- [x] Dedicated center scan CTA and 3-step receipt wizard
- [-] Receipt scan copy aligned with the current non-OCR reality
- [x] Account tools audit for primary/archive/net-worth consistency

### Insights and Coaching

- [x] Local dashboard with safe-to-spend and mission loop
- [x] Local savings playbook / strategy engine in dashboard
- [-] Insights simplified for B2C reading instead of report-heavy copy
- [x] Chart tap state now exposes exact selected values instead of a decorative-only chart
- [ ] Savings strategy suggestions surfaced consistently beyond dashboard
- [ ] Goal coaching and saving recommendations polished end-to-end

### Monetization Readiness

- [x] Premium screen aligned with current reality instead of fake live billing claims
- [x] Premium removed from the main tab bar and reduced to a cleaner plan-first surface
- [ ] Entitlement model documented for `Free`, `Premium`, and `Family`
- [>] StoreKit integration
- [>] RevenueCat integration
- [>] Real restore/manage subscription flows

### Support, Trust, and Export

- [x] Help / Support / Legal surfaces
- [x] Local export and support packet generation
- [x] Public/legal/billing/support copy aligned with current product truth

## Nice-to-Have

### Before Backend

- [ ] Personal demo workspace with seeded sample data
- [ ] Contextual premium gates instead of generic upsell language
- [ ] Savings goals with clearer weekly guardrails
- [ ] Better copy for family-oriented use cases without fake shared-state behavior
- [ ] Notification architecture stubs documented without pretending they are live

### After Backend / Store / Services

- [>] Family shared spaces
- [>] Cloud sync and cross-device restore
- [>] OCR receipt extraction
- [>] Local + remote notifications
- [>] Habit coach nudges
- [>] Geofence-based spending nudges with explicit opt-in
- [>] Real subscription billing and entitlement sync
- [>] Backend-driven household collaboration

## Current Priority Order

1. Finish the remaining Spanish-first copy sweep in `Receipt Scan`, `Premium`, and secondary flows below the top fold.
2. Run one deeper scroll QA pass for long secondary screens after the internal TestFlight build is processed.
3. Validate on device that no accidental horizontal drag remains on long settings/support routes.
4. Prepare the backend/store integration branch after internal tester feedback lands.

## Progress Notes

- 2026-04-03: `Auth`, `Onboarding`, `Dashboard`, `Expenses`, and `Receipt Scan` were simplified and significantly cleaned up.
- 2026-04-03: Merchant memory/autofill was added for manual expense entry and receipt draft capture.
- 2026-04-03: Dashboard now includes a local savings playbook based on utilization, hotspots, and reserve suggestions.
- 2026-04-03: Added a persistent feature checklist in `Docs/FEATURE_CHECKLIST.md` to track must-have and nice-to-have scope.
- 2026-04-03: `Premium` was reframed as an honest plan preview instead of implying live Store billing, sync, or restore.
- 2026-04-03: `Insights` now uses the user currency setting and the top-fold copy is more B2C and less report-like.
- 2026-04-03: `Accounts` was audited and fixed so `primary`, `archive`, and `net worth` behave consistently and the row actions are mobile-safe.
- 2026-04-03: `Bills`, `CSV Import`, `Budget Wizard`, `Onboarding`, `Support`, and local export now honor the configured currency and have Spanish-first copy on their visible flows.
- 2026-04-03: Visual QA screenshots were refreshed for `Onboarding`, `Auth`, `Dashboard`, `Accounts`, `Bills`, `CSV Import`, `Budget Wizard`, and `Support`.
- 2026-04-03: The app is effectively pre-TestFlight ready for internal UI/product validation, but an external beta should still wait for remaining placeholder scenes and clearer mock/live boundaries in a few advanced tools.
- 2026-04-03: Internal TestFlight build `1.0 (7)` was archived and uploaded successfully to App Store Connect for internal processing.
- 2026-04-04: Internal TestFlight build `1.0 (8)` was archived and uploaded after the Xcode 26 icon migration, splash/loading refresh, and final local art polish.
- 2026-04-04: Generated and integrated final local guide artwork for `Profile`, `Help`, `Rules`, and `Advanced` using the official mascot sprite library and registered them in the brand manifest.
- 2026-04-04: Dashboard game loop now surfaces mission cards, trophy rail, and live seasonal events; the growth system also ships with maintainable seasonal mission catalogs plus date-driven dashboard/splash/loading art overrides.
- 2026-04-04: Reworked the main shell so `Scan` is the center CTA, removed `Premium` from the main tab bar, and simplified the root screens with inline navigation chrome.
- 2026-04-04: `Receipt Scan` now behaves as a true 3-step wizard and protects user-edited category/date values from being overwritten by late OCR/autofill passes.
- 2026-04-04: `Expenses` was shortened into summary + recent activity + folded tools, `Add expense` now leads with the form, and the dashboard trophy shelf no longer requires horizontal swiping.
- 2026-04-04: QA screenshots were refreshed for splash, auth, dashboard, scan, insights, settings, and premium; the visible top folds are materially cleaner, though a full below-the-fold i18n pass still remains.
