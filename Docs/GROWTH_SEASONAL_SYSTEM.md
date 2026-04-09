# Growth Seasonal System

Last updated: 2026-04-09

## What landed

- `Dashboard` now exposes the main game loop near the top fold with level progress, mission cards, trophy rail, and a live-event slot.
- Core missions, cloud missions, special milestone missions, and seasonal event missions are defined from blueprints inside `SpendSage/Sources/Features/Growth/GrowthSnapshot.swift`.
- Seasonal art activation is centralized in `SpendSage/Sources/Core/Brand/BrandAssets.swift` and resolved automatically by `BrandAssetCatalog`.
- `TrophyHistoryView` now shows the full mission board grouped as `Local`, `Cloud`, and `Especial`, plus an explicit event calendar.

## Mission catalog shape

- Local missions stay permanent and map to reusable finance behaviors: logging expenses, protecting streaks, adding accounts, enabling bills, creating rules, and staying inside budget.
- Cloud missions react to authenticated sync, shared spaces, member growth, and invite flow.
- Special missions cover deeper savings milestones and active seasonal quests.
- Seasonal missions only join the active mission list when their date window is live.
- Seasonal mission progress uses event-window activity counts where possible instead of blindly reusing all-time totals.

## Active date windows

- Halloween Hunt: October 20 through November 2
- Holiday Gift Guard: December 1 through December 28
- New Year Reset: December 29 through January 14

## Seasonal art overrides

- `guide_01_dashboard_game_manchas`
- `guide_25_splash_team`
- `guide_26_loading_yarn_team`

The catalog swaps those keys to seasonal variants when the current date falls inside an active window.

## Local art regeneration

Run:

```bash
python3 scripts/generate_growth_seasonal_art.py
```

This regenerates:

- corrected `guide_01_dashboard_game_manchas_v2.png`
- Halloween and holiday dashboard/splash/loading scene variants
- event badges for Halloween, Holidays, and New Year

## Notes

- The corrected dashboard guide now uses the official `manchas_*` sprite family, which keeps Manchas at four paws instead of the broken five-paw render that shipped in the old scene.
- `New Year Reset` currently reuses the holiday scene pack and swaps the live-event copy/badge layer only.
