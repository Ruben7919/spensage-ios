# SpendSage External App Store Metadata

Last updated: 2026-04-08

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
- sincronizar un espacio personal autenticado entre dispositivos;
- invitar miembros del hogar a un espacio familiar compartido;
- seguir tu progreso con niveles, rachas, badges y celebraciones compartibles.

SpendSage está diseñado para iPhone con una experiencia mobile-first, una UI clara y personajes que acompañan el progreso sin volver la app pesada o confusa.

Privacidad primero:

- el inicio de sesión es obligatorio para usar la app;
- la build actual sigue siendo local-first, pero puede sincronizar datos financieros en sesiones autenticadas y por espacio compartido;
- no hay tracking publicitario activo;
- no hay geolocalización en background;
- no hay anuncios activos;
- notificaciones, calendario y ubicación son permisos opcionales;
- el escaneo de recibos usa procesamiento local asistido y requiere revisión del usuario;
- diagnósticos de estabilidad y eventos de producto se recogen first-party, sin SDKs analíticos de terceros.

SpendSage es una app de apoyo para finanzas personales. No es un banco ni reemplaza asesoría financiera, legal o tributaria profesional.
```

## What’s New for Version 1.0

```text
Pulimos la experiencia de iPhone con sync autenticado, espacios familiares compartidos con invites, notificaciones opcionales, suscripciones nativas con StoreKit, mejores gráficas y un presupuesto paso a paso más amable.
```

## App Review Notes

```text
SpendSage es una app de finanzas personales local-first para iPhone.

Puntos importantes para revisión:
1. La build actual no usa anuncios, tracking entre apps ni geolocalización en background.
2. El inicio de sesión es obligatorio. El reviewer puede crear una cuenta nueva con email o continuar con Apple / Google desde la primera pantalla.
3. Esta línea de TestFlight beta externa sigue apuntando al backend autenticado `dev`. Eso es intencional para esta beta.
4. El escaneo de recibos usa VisionKit/Vision en el dispositivo para asistencia local; el usuario revisa y corrige el borrador antes de guardar.
5. Notificaciones, ubicación y calendario son permisos opcionales y se disparan desde Ajustes o desde acciones explícitas del usuario.
6. La app ahora incluye sync autenticado, espacios familiares compartidos e invites, pero la revisión puede enfocarse en el flujo personal autenticado si lo prefiere.
7. Los diagnósticos de estabilidad y eventos de producto son first-party; no hay SDKs analíticos de terceros.
8. La app incluye Centro legal dentro de la navegación y la política de privacidad también se publica en el campo de Privacy Policy URL.
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
  - The current Release/TestFlight target still points to the authenticated `dev` backend, so treat this as external beta guidance, not public-launch guidance.
  - Store review copy should describe authenticated sync and shared spaces conservatively as beta functionality, not as a public-launch guarantee.
  - RevenueCat or App Store Server backend reconciliation is still optional future work; current beta validation is native StoreKit-first.

Configured store pricing source of truth:

- `spendsage.remove_ads`: `USD 14.99`
- `spendsage.pro.monthly`: `USD 5.99`
- `spendsage.pro.annual`: `USD 39.99`
- `spendsage.family.monthly`: `USD 9.99`
- `spendsage.family.annual`: `USD 69.99`

Current App Store Connect sync state:

- The local source of truth is ready and updated for authenticated sync, family spaces, push, and first-party reliability telemetry.
- The 2026-04-08 authenticated sync did update app/version/beta metadata from the current source of truth.
- Global territory pricing is now applied for all five monetization SKUs, which was the missing piece keeping the four auto-renewable subscriptions out of reviewable state.
- `spendsage.pro.monthly`, `spendsage.pro.annual`, `spendsage.family.monthly`, `spendsage.family.annual`, and `spendsage.remove_ads` are now `READY_TO_SUBMIT`.
- Version `1.0` in App Store Connect now includes all five monetization components in the `Compras dentro de la app y suscripciones` section.
- Build `1.0 (29)` was uploaded on 2026-04-09, processed as `VALID`, attached to the configured external TestFlight group, and is now `APPROVED` for external beta testing.
- Internal testers receive the same App Store eligible build automatically once processed; App Store Connect rejected a separate internal-group attachment for this App Store eligible build type, so the automation records it as `automatic`.
- Re-apply from the authenticated Chrome session before each external-beta upload.

## Submission Positioning

Use the current external narrative:

- simple personal finance;
- fast expense capture;
- guided receipt scan;
- clear budget and monthly insight loop;
- authenticated sync and shared household spaces;
- playful progress system;
- privacy-conscious local-first behavior.

Avoid leading with:

- family collaboration or sync as if they were already public-launch mature;
- advanced AI coaching as if already live;
- geofence nudges as if already live;
- live cloud premium unlocks unless they are enabled and reviewable end-to-end.
