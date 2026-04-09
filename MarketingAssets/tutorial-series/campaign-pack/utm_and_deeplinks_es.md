# SpendSage UTM and Deep Links

Ultima actualizacion: 2026-04-09

## 1. Regla base de UTM

Usar siempre:

- `utm_source`: plataforma exacta
- `utm_medium`: formato
- `utm_campaign`: nombre de campana
- `utm_content`: pieza puntual

Campana base Sprint 1:

- `utm_campaign=spendsage_en_7_pasos`

## 2. URLs de landing sugeridas

### YouTube Shorts

- `https://spendsage.ai/?utm_source=youtube&utm_medium=shorts&utm_campaign=spendsage_en_7_pasos&utm_content=tutorial_01`
- `https://spendsage.ai/?utm_source=youtube&utm_medium=shorts&utm_campaign=spendsage_en_7_pasos&utm_content=tutorial_07`

### Instagram Reels

- `https://spendsage.ai/?utm_source=instagram&utm_medium=reels&utm_campaign=spendsage_en_7_pasos&utm_content=tutorial_03`

### TikTok

- `https://spendsage.ai/?utm_source=tiktok&utm_medium=organic_video&utm_campaign=spendsage_en_7_pasos&utm_content=tutorial_05`

### Bio link general

- `https://spendsage.ai/?utm_source=social_bio&utm_medium=linkhub&utm_campaign=spendsage_en_7_pasos&utm_content=main_entry`

## 3. App Store y beta

- App Store publico actual: `https://apps.apple.com/app/id6761512773`
- Acceso beta actual: no hay link publico de TestFlight versionado dentro del repo.
- Ruta correcta mientras tanto: `mailto:support@spendsage.ai?subject=Quiero%20acceso%20a%20la%20beta%20de%20SpendSage`

## 4. Deep links basicos ya soportados en app

Estos atajos usan el esquema `spendsage://` y funcionan cuando la app ya esta instalada.

- `spendsage://open?tab=dashboard`
- `spendsage://open?tab=expenses`
- `spendsage://open?tab=scan`
- `spendsage://open?tab=insights`
- `spendsage://open?tab=settings`
- `spendsage://open?sheet=add-expense`
- `spendsage://open?sheet=budget`

Tambien se aceptan aliases simples en espanol:

- `spendsage://open?tab=inicio`
- `spendsage://open?tab=gastos`
- `spendsage://open?tab=analisis`
- `spendsage://open?tab=ajustes`
- `spendsage://open?sheet=presupuesto`

## 5. Nota operativa

- Estos deep links basicos asumen sesion autenticada.
- Si el usuario no ha iniciado sesion, la app muestra un aviso y continua su flujo normal.
- Cuando exista un link publico de TestFlight, reemplazar el CTA de beta privada sin tocar la taxonomia UTM.
