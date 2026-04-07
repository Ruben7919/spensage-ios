# SpendSage External App Store Metadata

Last updated: 2026-04-07

## Automation Source Of Truth

- App Store Connect metadata source: `/Users/rubenlazaro/Projects/spensage-ios/AppStoreAssets/app_store_connect_config.json`
- Browser automation helper: `/Users/rubenlazaro/Projects/spensage-ios/scripts/app_store/chrome_apple_events.py`
- Metadata apply script: `/Users/rubenlazaro/Projects/spensage-ios/scripts/app_store/app_store_connect_apply.py`
- Session-backed metadata/pricing sync: `/Users/rubenlazaro/Projects/spensage-ios/scripts/app_store/app_store_connect_iris_sync.py`
- Session-backed screenshot sync: `/Users/rubenlazaro/Projects/spensage-ios/scripts/app_store/app_store_connect_screenshots_sync.py`
- Archive and upload script: `/Users/rubenlazaro/Projects/spensage-ios/scripts/app_store/archive_and_upload.sh`

The current automation assumes an already authenticated App Store Connect session in Google Chrome on this Mac.

## Publication URLs

- Marketing URL: `https://cz2vxbcze4.execute-api.us-east-1.amazonaws.com/dev/public/legal/disclaimer`
- Support URL: `https://cz2vxbcze4.execute-api.us-east-1.amazonaws.com/dev/public/legal/support-and-contact`
- Privacy Policy URL: `https://cz2vxbcze4.execute-api.us-east-1.amazonaws.com/dev/public/legal/privacy-policy`
- Terms of Use URL: `https://cz2vxbcze4.execute-api.us-east-1.amazonaws.com/dev/public/legal/terms-of-service`
- Legal hub URL: `https://cz2vxbcze4.execute-api.us-east-1.amazonaws.com/dev/public/legal`

These URLs respond today from the live backend. Replace them with branded production domains before public App Store launch.

## Product Identity

- App name: `SpendSage AI`
- Subtitle: `Gastos, recibos y presupuesto fácil`
- Primary category: `Finance`
- Secondary category: `Productivity`
- Content rights owner: `Ruben Lazaro`

## Promotional Text

```text
Controla gastos, escanea recibos y entiende tu mes con una app clara, cute y poderosa desde tu iPhone.
```

## Keywords

```text
gastos,ahorro,presupuesto,recibos,finanzas,scanner,control,metas,budget,expense
```

## Full Description

```text
SpendSage te ayuda a registrar gastos, escanear recibos y cuidar tu presupuesto sin sentir que estás administrando una hoja de cálculo.

Registra compras rápido, revisa el mes con claridad y usa el escaneo de recibos para crear un borrador editable antes de guardar. La experiencia está pensada para sentirse simple desde el primer minuto, pero lo bastante útil para darte contexto real sobre cómo vas este mes.

Con SpendSage puedes:

- registrar gastos manualmente en segundos;
- escanear recibos con ayuda local en el dispositivo;
- revisar y corregir el borrador antes de guardar;
- ver análisis simples y tocar gráficas para leer el valor exacto;
- configurar un presupuesto guiado paso a paso;
- seguir tu progreso con niveles, rachas, badges y celebraciones compartibles.

SpendSage está diseñado para iPhone con una experiencia mobile-first, una UI clara y personajes que acompañan el progreso sin volver la app pesada o confusa.

Privacidad primero:

- la build actual es principalmente local-first;
- no hay tracking publicitario activo;
- no hay geolocalización activa;
- no hay anuncios activos;
- el escaneo de recibos usa procesamiento local asistido y requiere revisión del usuario.

SpendSage es una app de apoyo para finanzas personales. No es un banco ni reemplaza asesoría financiera, legal o tributaria profesional.
```

## What’s New for Version 1.0

```text
Pulimos la primera experiencia de iPhone con un dashboard más claro, dock inferior anclado, captura de gastos más limpia, escaneo guiado de recibos, análisis simples y presupuesto paso a paso.
```

## App Review Notes

```text
SpendSage es una app de finanzas personales local-first para iPhone.

Puntos importantes para revisión:
1. La build actual no usa anuncios, tracking entre apps, geolocalización ni notificaciones push.
2. El escaneo de recibos usa VisionKit/Vision en el dispositivo para asistencia local; el usuario revisa y corrige el borrador antes de guardar.
3. La app incluye Centro legal dentro de la navegación y la política de privacidad también se publica en el campo de Privacy Policy URL.
4. Si el flujo de autenticación cloud está activo para esta submission, proporcione credenciales o un método de acceso de revisión antes de enviar.
5. No describa como activas funciones que todavía no estén vivas en backend o billing al momento exacto de la submission.
```

## Review Contact

These fields are required in App Store Connect but still need live values before final submission if they aren't already configured in the account:

- Contact name: `Ruben Lazaro`
- Contact email: `support@spendsage.ai`
- Contact phone: `+593969686491`

## Age Rating Guidance

Recommended current answers:

- Gambling: `No`
- Contests: `No`
- Medical or treatment content: `No`
- User-generated content: `No`
- Unrestricted web access: `No`
- Location sharing: `No`
- Mature or suggestive themes: `No`
- Violence, weapons, horror, drugs, alcohol, tobacco: `No`

Recommended resulting rating for the current implementation: `4+`

## Pricing / Availability Guidance

- Availability: countries where support and legal pages are published and maintained
- Price: `Free`
- Monetization state for current external submission:
  - StoreKit 2 native purchase / restore wiring now exists in the iOS app.
  - App Store Connect products now exist for `spendsage.pro.monthly`, `spendsage.pro.annual`, `spendsage.family.monthly`, `spendsage.family.annual`, and `spendsage.remove_ads`.
  - Store review copy and public metadata must still avoid claiming cloud entitlements are active until backend reconciliation is live.
  - Keep paid plans disabled for an external submission until pricing, localizations, and backend entitlement sync are reviewable end-to-end.

Configured store pricing source of truth:

- `spendsage.remove_ads`: `USD 7.99`
- `spendsage.pro.monthly`: `USD 4.99`
- `spendsage.pro.annual`: `USD 29.99`
- `spendsage.family.monthly`: `USD 7.99`
- `spendsage.family.annual`: `USD 49.99`

Current App Store Connect sync status:

- App info localizations are synced for `en-US` and `es-ES`.
- App version localizations are synced for `en-US` and `es-ES`.
- App Review contact and notes are synced.
- iPhone screenshot sets are uploaded for `en-US` and `es-ES` using the current 6-shot pack.

## Submission Positioning

Use the current external narrative:

- simple personal finance;
- fast expense capture;
- guided receipt scan;
- clear budget and monthly insight loop;
- playful progress system;
- privacy-conscious local-first behavior.

Avoid leading with:

- family collaboration as if already live;
- cloud sync as if already live;
- advanced AI coaching as if already live;
- geofence nudges as if already live;
- live cloud premium unlocks unless they are enabled and reviewable end-to-end.
