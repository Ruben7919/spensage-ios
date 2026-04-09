# Seasonal Event Calendar

Last updated: 2026-04-09

## Shipped windows

| Season | Active window | Missions | Live badge | Main scene swaps |
| --- | --- | --- | --- | --- |
| Halloween Hunt | October 20 to November 2 | `Halloween sin sustos`, `Captura los extras` | `badge_event_halloween_v2.png` | dashboard, splash, loading |
| Holiday Gift Guard | December 1 to December 28 | `Regalos bajo control`, `Diciembre con vista clara` | `badge_event_holiday_v2.png` | dashboard, splash, loading |
| New Year Reset | December 29 to January 14 | `Arranque limpio`, `Vuelve al ritmo` | `badge_event_new_year_v2.png` | dashboard, splash, loading |

## Character art packs shipped

These guides were added so each live season has explicit character art, not only a team splash:

### Halloween Hunt

- `guide_27_tikki_halloween_v2.png`
- `guide_28_mei_halloween_v2.png`
- `guide_29_manchas_halloween_v2.png`

### Holiday Gift Guard

- `guide_30_tikki_holiday_v2.png`
- `guide_31_mei_holiday_v2.png`
- `guide_32_manchas_holiday_v2.png`

### New Year Reset

- `guide_33_tikki_new_year_v2.png`
- `guide_34_mei_new_year_v2.png`
- `guide_35_manchas_new_year_v2.png`

## Seasonal sprite pack shipped

- Full seasonal sprite variants now exist for every shipped expression of `tikki`, `mei`, and `manchas`.
- Naming convention:
  - `*_halloween_v2.png`
  - `*_holiday_v2.png`
  - `*_new_year_v2.png`
- The runtime resolves these variants automatically during an active season from `BrandAssetCatalog.character(...)`.
- Regeneration script:
  - `/Users/rubenlazaro/Projects/spensage-ios/scripts/generate_seasonal_character_pack.py`
- Manual browser prompt pack:
  - `/Users/rubenlazaro/Projects/spensage-ios/Docs/prompts/SEASONAL_SPRITE_PACK_PROMPTS.md`

## Team scene swaps shipped

- `guide_01_dashboard_game_manchas_halloween_v2.png`
- `guide_01_dashboard_game_manchas_holiday_v2.png`
- `guide_25_splash_team_halloween_v2.png`
- `guide_25_splash_team_holiday_v2.png`
- `guide_26_loading_yarn_team_halloween_v2.png`
- `guide_26_loading_yarn_team_holiday_v2.png`

## Activation rules

- The active season is resolved by `BrandSeasonCatalog` in `/Users/rubenlazaro/Projects/spensage-ios/SpendSage/Sources/Core/Brand/BrandAssets.swift`.
- Mission activation is resolved in `/Users/rubenlazaro/Projects/spensage-ios/SpendSage/Sources/Features/Growth/GrowthSnapshot.swift`.
- The brand manifest that exposes all seasonal guide assets lives in `/Users/rubenlazaro/Projects/spensage-ios/SpendSage/Resources/Brand/v2/asset_manifest.json`.
- Seasonal art generation is reproducible from `/Users/rubenlazaro/Projects/spensage-ios/scripts/generate_growth_seasonal_art.py`.

## UI surfaces already using the seasonal system

- Dashboard live event card
- Trophy history event calendar
- Dashboard quest art
- Splash screen
- Loading screen with yarn animation
- Brand Gallery seasonal pack review

## Backlog, not shipped yet

- Valentine savings streak
- Easter budget basket
- Back-to-school reset
- Black Friday impulse shield
- Birthday week treat budget

## Art guardrails

- Keep the official `tikki`, `mei`, and `manchas` families intact.
- No extra limbs, duplicate paws, or off-model anatomy.
- Prefer seasonal scene variants over replacing the core expression library unless there is a real gameplay need.
