# SpendSage iOS Feature Checklist

Last updated: 2026-04-07

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
- [x] Final pre-TestFlight visual QA across all main and secondary routes
- [x] Root tabs now use simpler inline navigation chrome instead of large-title duplication
- [x] Internal TestFlight archive and upload
- [x] Internal TestFlight build `1.0 (10)` uploaded with the repaired three-mascot icon and final route QA pass
- [x] Shareable celebration overlay for level-ups and badges
- [x] One-time in-app review prompt policy tied to positive progress moments

### Route Coverage

- [x] `Inicio` simplified for B2C daily use
- [x] `Gastos` simplified with scan-first capture flow
- [x] `Scan` 3-step wizard with editable autofill review
- [x] `Análisis` simplified with tappable chart values
- [x] `Ajustes` split into lighter navigation instead of one long wall
- [x] Secondary routes for `Help`, `Support`, `Legal`, `Profile`, `Advanced`, and `Budget Wizard`

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
- [x] Insights simplified for B2C reading instead of report-heavy copy
- [x] Chart tap state now exposes exact selected values instead of a decorative-only chart
- [ ] Savings strategy suggestions surfaced consistently beyond dashboard
- [ ] Goal coaching and saving recommendations polished end-to-end
- [x] Mission XP now feeds the visible progression loop
- [x] Mission and badge progress stay locally durable instead of vanishing with later state edits

### Monetization Readiness

- [x] Premium screen aligned with current reality instead of fake live billing claims
- [x] Premium removed from the main tab bar and reduced to a cleaner plan-first surface
- [ ] Entitlement model documented for `Free`, `Premium`, and `Family`
- [x] StoreKit integration
- [>] RevenueCat integration
- [x] Real restore/manage subscription flows
- [x] App Store Connect metadata and upload automation scripts added under `scripts/app_store/`
- [x] App Store Connect app metadata, review notes, pricing metadata, and localized screenshot sets synced through the authenticated ASC session

### Support, Trust, and Export

- [x] Help / Support / Legal surfaces
- [x] Local export and support packet generation
- [x] Public/legal/billing/support copy aligned with current product truth

### Brand, Art, and Content

- [x] Main mascot expression pack for `tikki`, `mei`, and `manchas`
- [x] Seasonal mascot sprite pack for Halloween, Holiday, and New Year
- [x] Main guide scenes for dashboard, budgets, insights, scan, family, profile, help, rules, and advanced tools
- [x] Badge art pack for missions, streaks, savings, premium, and seasonal events
- [x] Splash artwork with default and seasonal swaps
- [x] Loading artwork and yarn-ball loading animation
- [x] Xcode 26 app icon variants `Any`, `Dark`, and `Tinted`
- [x] Prompt documentation for icon, splash, loading, and seasonal sprite generation
- [ ] Additional event art backlog beyond the three shipped seasons

### Legal, Release, and Compliance

- [x] Privacy Policy drafted in Spanish
- [x] Terms of Use drafted in Spanish
- [x] Beta Notice and Disclosures drafted in Spanish
- [x] Support and Contact policy drafted in Spanish
- [x] Legal documents bundled and rendered inside the app
- [x] Legal docs updated with declared operator identity for `Ruben Lazaro`
- [x] Declared operator tax ID captured as `RUC 0924829179001`
- [x] Declared operator address captured as `Samanes 4 Mz 408 Villa 130112`
- [x] External App Store metadata package prepared
- [x] External App Privacy response matrix prepared
- [x] External iPhone 6.9 screenshot pack prepared with blurred data and mascot side composition
- [x] Public-site content staged for `spendsage.ai` and `legal.spendsage.ai`
- [-] Final lawyer review before public production release

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
- 2026-04-04: QA screenshots were refreshed for splash, auth, dashboard, scan, insights, settings, and premium; the visible top folds are materially cleaner.
- 2026-04-04: Added explicit seasonal calendar docs plus shipped Halloween, Holiday, and New Year character guide packs so event art is now auditable beyond the team splash/loading scenes.
- 2026-04-04: Shipped a full seasonal sprite pack for all mascot expressions, wired it into `BrandAssetCatalog.character(...)`, and documented manual browser prompts plus regeneration scripts for future art passes.
- 2026-04-04: Internal TestFlight build `1.0 (9)` was archived and uploaded successfully with the seasonal sprite runtime pack, Xcode 26 icon variants, and the latest B2C shell/scan polish.
- 2026-04-05: Added a full celebration overlay for level-up, badge unlock, and mission completion moments, including share-to-social support and an app-review prompt policy that only triggers after meaningful positive progress.
- 2026-04-05: Simplified and translated the main navigation surfaces again, covering `Inicio`, `Gastos`, `Análisis`, `Ajustes`, `Agregar gasto`, the budget wizard, and the first-run guides with a cleaner Spanish-first UX.
- 2026-04-05: Trophy History now exposes the full mission board, not just badges, so the growth loop is visible beyond the dashboard top fold.
- 2026-04-05: Growth progress now persists locally for completed missions and unlocked trophies, and mission reward XP is reflected in the visible progression level instead of being decorative-only.
- 2026-04-05: Refreshed visual QA for `Inicio`, `Gastos`, `Análisis`, `Ajustes`, and celebration states after the final i18n/navigation polish pass.
- 2026-04-05: Rebuilt the app icon as a three-mascot peeking composition for the Xcode 26 `Any`, `Dark`, and `Tinted` icon variants, then refreshed a full route QA pass covering onboarding, auth, the 5 root tabs, celebration state, and the main deep-link settings/support tools.
- 2026-04-05: Final polish reduced heavy legal/profile/advanced heroes, surfaced receipt scan actions in the first fold, removed more internal-looking `preview` copy from user-facing screens, and tightened the celebration overlay before the next internal TestFlight upload.
- 2026-04-05: Internal TestFlight build `1.0 (10)` uploaded successfully after removing alpha from the Xcode 26 icon assets and re-running the full route QA repair pass.
- 2026-04-05: Legal documentation was updated with the declared current operator identity: `Ruben Lazaro`, `RUC 0924829179001`, `Samanes 4 Mz 408 Villa 130112`.
- 2026-04-05: Prepared the external release package with App Store metadata, App Privacy mapping, iPhone 6.9 screenshots with blurred data and mascot-side compositions, plus staged public-site legal/support content for `spendsage.ai` and `legal.spendsage.ai`.
- 2026-04-07: Reworked the App Store Connect automation to use the logged-in Chrome session directly, synced `en-US` + `es-ES` metadata, updated App Review contact details, and uploaded the current 6-shot iPhone screenshot pack to both locales.
