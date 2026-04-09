# SpendSage Sprint 2 Growth System

Última actualización: 2026-04-09

## Estado

Sprint 2 queda implementado como sistema base de growth:

- Dashboard v0 de métricas y funnel: `/Users/rubenlazaro/Projects/spensage-ios/MarketingAssets/growth-sprint-2/growth_dashboard.html`
- Mapa de eventos/KPIs: `/Users/rubenlazaro/Projects/spensage-ios/MarketingAssets/growth-sprint-2/growth_funnel_events.csv`
- Lifecycle push/email básico: `/Users/rubenlazaro/Projects/spensage-ios/MarketingAssets/growth-sprint-2/lifecycle_push_email_es.md`
- Brief de paid testing: `/Users/rubenlazaro/Projects/spensage-ios/MarketingAssets/growth-sprint-2/paid_testing_brief_es.md`
- Creatives paid-testing: `/Users/rubenlazaro/Projects/spensage-ios/MarketingAssets/launch-campaign/posters`

## Producto

La solicitud de rating/review ya existía antes de este Sprint:

- `AppReviewPromptPolicy` decide cuándo pedir review después de una señal positiva real.
- `AppRootView` llama `requestReview()` cuando `reviewPromptToken` cambia.
- `GrowthCelebrationTests` cubre que el prompt solo ocurra antes de marcarse como consumido.

En Sprint 2 se añadieron señales de funnel first-party sin enviar montos exactos ni comercios:

- `expense_saved`
- `receipt_scan_expense_saved`
- `budget_saved`

Estas señales completan el puente mínimo entre adquisición, activación y valor de producto.

## Dashboard

North Star Metric:

`Usuarios activados: completaron onboarding y guardaron primer gasto, escaneo o presupuesto dentro de los primeros 7 días.`

KPIs iniciales:

- CTR social/paid: 1.8%+
- Install/TestFlight join rate: 22%+
- Activation rate: 45%+
- D7 value signal: 18%+

## Lifecycle

La secuencia básica se concentra en una acción por mensaje:

- D0: guardar primer gasto.
- D1: probar escaneo si ya existe gasto.
- D3: crear presupuesto.
- D7: revisar progreso/logro.
- D14: win-back sin culpa.

## Paid testing

Los 5 ángulos creativos quedan listos para test:

- Caos a claridad.
- Escaneo con control.
- Dato que ayuda.
- Logro compartible.
- Hogar más claro.

Regla de decisión:

- Si no hay CTR, iterar hook.
- Si hay CTR pero no install, revisar landing/App Store.
- Si hay install pero no activación, revisar onboarding y CTA inicial.
