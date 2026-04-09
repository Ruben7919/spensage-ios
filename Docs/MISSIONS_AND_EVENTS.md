# Missions And Events

Last updated: 2026-04-09

## Mission board shape

The mission board now ships in three user-facing tracks so the app feels easier to understand:

- `Local`: daily and weekly habits that improve budgeting on this device.
- `Cloud`: backup, shared-space, and family collaboration steps.
- `Special`: bigger milestone missions plus live seasonal quests.

The runtime catalog lives in `/Users/rubenlazaro/Projects/spensage-ios/SpendSage/Sources/Features/Growth/GrowthSnapshot.swift`.

## Local missions shipped

- `Despierta tu ahorro`: log 3 real expenses so the app starts reading spending habits.
- `Cuatro días en ritmo`: keep a 4-day streak to stabilize the routine.
- `Mapa del dinero`: add 2 account buckets so spending and savings stop mixing.
- `Radar de pagos`: add 1 recurring bill to surface future pressure earlier.
- `Autopiloto inteligente`: create 1 smart rule for repeated merchants.
- `Mes en verde`: keep the current month inside budget.

## Cloud missions shipped

- `Respaldo al día`: finish one successful authenticated sync.
- `Casa compartida`: join or create a shared family space.
- `Primer asiento ocupado`: reach 2 members inside a shared space.
- `Invitación enviada`: send the first family invite when the caller can invite members.

## Special missions shipped

- `Base de ahorro armada`: complete the setup trio of 2 accounts + 1 bill + 1 rule.
- `Semana bajo control`: reach the full rhythm score of 8 transactions + 4 active days + budget still green.

## Seasonal missions shipped

### Halloween Hunt

- `Halloween sin sustos`
- `Captura los extras`

### Holiday Gift Guard

- `Regalos bajo control`
- `Diciembre con vista clara`

### New Year Reset

- `Arranque limpio`
- `Vuelve al ritmo`

## Event calendar shipped

- The trophy history screen now includes a dedicated `Calendario de eventos` section.
- It lists each shipped season, its current status (`Activo` or `Próximo`), the date window, and the featured mission titles.
- The dashboard still surfaces the current or next live event near the top fold for faster discovery.

## Seasonal art behavior shipped

- The active season swaps dashboard quest art, splash art, loading art, and live-event badge art automatically by date.
- `Halloween Hunt` uses dedicated dashboard, splash, loading, and badge variants.
- `Holiday Gift Guard` uses dedicated dashboard, splash, loading, and badge variants.
- `New Year Reset` currently reuses the holiday scene pack and swaps the live-event copy plus New Year badge.

## Badge art note

- This update keeps the current badge family so the shipped visual style stays consistent with existing trophies.
- If the team wants custom art for the new `cloud` or `special` mission families later, use `/Users/rubenlazaro/Projects/spensage-ios/Docs/prompts/MISSION_BADGE_REFRESH_PROMPTS.md`.
