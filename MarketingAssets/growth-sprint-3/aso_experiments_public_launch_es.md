# Sprint 3 ASO Experiments para Public Launch

Última actualización: 2026-04-09

## Objetivo

Preparar tests ASO para lanzamiento público sin cambiar todavía la metadata estable de external beta.

La prioridad es descubrir qué promesa convierte mejor:

- velocidad: registrar y escanear rápido;
- claridad: entender el mes sin complicarse;
- progreso: hábitos y logros pequeños;
- hogar: gastos compartidos y reglas familiares.

## Métrica Principal

Conversión desde impresión de App Store a descarga/TestFlight join.

Métricas secundarias:

- tap-through rate del producto;
- screenshot engagement;
- activation rate dentro de los primeros 7 días;
- primer gasto, primer escaneo o primer presupuesto.

## Experimentos

### A. Subtitle

Control:

```text
Gastos, recibos y presupuesto fácil
```

Variante 1:

```text
Gastos claros desde el iPhone
```

Variante 2:

```text
Escanea recibos y entiende tu mes
```

Variante 3:

```text
Presupuesto simple y progreso real
```

### B. Promotional Text

Control:

```text
Controla gastos, escanea recibos y entiende tu mes con una app clara, cute y poderosa desde tu iPhone.
```

Variante 1:

```text
Empieza con una compra real: registra gastos, escanea recibos y mira tu mes con más claridad.
```

Variante 2:

```text
Una forma más amable de registrar gastos, revisar recibos y convertir tus datos en próximos pasos.
```

### C. Screenshot 1

Control: home/dashboard con gasto reciente.

Variante 1: escaneo de recibo con copy `Foto, revisa y guarda`.

Variante 2: análisis con tooltip y copy `Toca el dato y decide`.

Variante 3: logro compartible con copy `Celebra el avance`.

### D. Icono

Control: icono actual.

Variante 1: acento teal más visible y símbolo de recibo.

Variante 2: gato/mascota simplificado si el asset mantiene legibilidad a 60 px.

Variante 3: marca abstracta de progreso, evitando parecer app bancaria genérica.

## Keywords

Mantener foco inicial:

```text
gastos,ahorro,presupuesto,recibos,finanzas,scanner,control,metas,budget,expense
```

Backlog para evaluar:

- `organizador gastos`
- `recibos`
- `budget planner`
- `expense tracker`
- `finanzas personales`
- `ahorro mensual`

## Reglas de Decisión

- No cambiar más de una variable fuerte por test si se necesita aprendizaje claro.
- Si subtitle mejora impresiones pero no activación, revisar si promete demasiado.
- Si screenshot de escaneo sube conversión pero baja activación, ajustar onboarding hacia primer scan.
- Si logro compartible convierte bien en social pero no en App Store, reservarlo para ads y no para screenshot 1.

## Output de Sprint 3

- Matriz CSV de experimentos: `/Users/rubenlazaro/Projects/spensage-ios/MarketingAssets/growth-sprint-3/aso_experiments.csv`
- Board visual de Sprint 3: `/Users/rubenlazaro/Projects/spensage-ios/MarketingAssets/growth-sprint-3/sprint3_board.html`
- Carouseles/feed pack: `/Users/rubenlazaro/Projects/spensage-ios/MarketingAssets/launch-campaign/posters`
