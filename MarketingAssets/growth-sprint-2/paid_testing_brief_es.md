# Sprint 2 Paid Testing Brief

Objetivo: probar 5 ángulos B2C antes de escalar presupuesto. Esta tanda no busca “vender finanzas perfectas”; busca confirmar qué promesa mueve a usuarios de 20 a 30 años a instalar y completar la primera acción.

## Setup recomendado

- Presupuesto inicial: bajo, 3 a 5 días por tanda.
- Optimización inicial: click o landing view si no hay suficiente volumen de install.
- UTM base: `utm_campaign=michifinanzas_sprint2_paid_test`.
- Variable principal: `utm_content` por ángulo creativo.
- No escalar un anuncio solo por views; priorizar CTR, install rate y activation rate.

## Creatives

### 1. Caos a claridad

Asset: `paid_story_01_caos_a_claro.png`

Hook:

`¿Gastos en la cabeza?`

Caption:

`Cuando todo está suelto, empezar pequeño ayuda. Guarda una compra real y deja que MichiFinanzas te ayude a ver el primer paso.`

CTA:

`Probar MichiFinanzas`

UTM:

`utm_content=paid_story_01_caos_a_claro`

### 2. Escaneo con control

Asset: `paid_story_02_escaneo_control.png`

Hook:

`Foto, revisa y guarda`

Caption:

`Escanear rápido está bien, pero revisar antes de guardar está mejor. MichiFinanzas mantiene el control en tus manos.`

CTA:

`Escanear un recibo`

UTM:

`utm_content=paid_story_02_escaneo_control`

### 3. Dato que ayuda

Asset: `paid_story_03_dato_que_ayuda.png`

Hook:

`Tu gráfico sí te habla`

Caption:

`No abras una app para ver números muertos. Toca, entiende y decide qué hacer después con tus gastos.`

CTA:

`Ver cómo funciona`

UTM:

`utm_content=paid_story_03_dato_que_ayuda`

### 4. Logro compartible

Asset: `paid_story_04_logro_compartible.png`

Hook:

`Celebra lo pequeño`

Caption:

`Un hábito financiero no nace perfecto. Si avanzaste hoy, MichiFinanzas te lo muestra y te deja compartirlo si quieres.`

CTA:

`Ver logros`

UTM:

`utm_content=paid_story_04_logro_compartible`

### 5. Hogar más claro

Asset: `paid_story_05_hogar_mas_claro.png`

Hook:

`Tu hogar más claro`

Caption:

`Cuentas, reglas y facturas no tienen que vivir en mil notas. Ordénalas en una ruta simple y vuelve cuando lo necesites.`

CTA:

`Ordenar mi mes`

UTM:

`utm_content=paid_story_05_hogar_mas_claro`

## Métrica de corte

- Cortar si CTR < 0.8% después de volumen mínimo razonable.
- Iterar hook si CTR es bueno pero install rate bajo.
- Iterar landing/App Store si CTR es bueno e install rate flojo en todos los ángulos.
- Iterar onboarding si installs llegan pero `onboarding_completed` y `expense_saved` quedan bajos.
