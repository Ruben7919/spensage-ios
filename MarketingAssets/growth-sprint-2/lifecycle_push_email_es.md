# Sprint 2 Lifecycle Push + Email

Objetivo: activar usuarios nuevos sin sonar invasivos. La secuencia debe sentirse como ayuda corta, no como presión financiera.

## Reglas de tono

- No culpar al usuario por gastar.
- No mencionar montos exactos en push.
- No pedir notificaciones antes de que el usuario vea valor.
- Mantener cada push en una sola acción.
- Email puede explicar más, pero debe terminar con un CTA claro.

## Push básico

### D0 · Primer gasto

Segmento: usuario con `onboarding_completed` y sin `expense_saved`.

Push:

`Empieza simple: guarda una compra real y deja que SpendSage ordene el primer paso contigo.`

CTA app:

`Abrir registro de gasto`

### D1 · Escaneo

Segmento: usuario con `expense_saved` y sin `receipt_scan_expense_saved`.

Push:

`Si tienes un recibo cerca, pruébalo: escanea, revisa y guarda solo si todo se ve bien.`

CTA app:

`Escanear recibo`

### D3 · Presupuesto

Segmento: usuario con `expense_saved` y sin `budget_saved`.

Push:

`Dale un marco a tu mes: arma un presupuesto rápido y vuelve cuando quieras ajustarlo.`

CTA app:

`Abrir presupuesto`

### D7 · Progreso

Segmento: usuario con alguna misión o badge desbloqueado.

Push:

`Tu avance ya cuenta. Mira qué cambió esta semana y celebra el paso que sí hiciste.`

CTA app:

`Ver progreso`

### Win-back D14

Segmento: usuario sin actividad por 14 días.

Push:

`Vuelve sin drama: solo guarda una compra reciente y retoma desde ahí.`

CTA app:

`Registrar gasto`

## Email básico

### Email 1 · Bienvenida

Asunto:

`Empieza con una compra, no con una hoja de cálculo`

Body:

`SpendSage está pensado para que empieces pequeño: registra un gasto real, revisa cómo queda y sigue cuando tengas tiempo. No tienes que organizar todo tu mes hoy.`

CTA:

`Guardar mi primer gasto`

### Email 2 · Escaneo

Asunto:

`Un recibo también puede ser un primer paso`

Body:

`Si tienes un recibo a mano, úsalo como prueba rápida. SpendSage puede ayudarte a leerlo, pero tú revisas antes de guardar. La idea es avanzar con control.`

CTA:

`Probar escaneo`

### Email 3 · Presupuesto

Asunto:

`Dale un plan simple a tu mes`

Body:

`Cuando ya tienes algunos gastos guardados, el presupuesto se vuelve más útil. Define un marco mensual y deja que SpendSage te ayude a leer el resto con más calma.`

CTA:

`Crear presupuesto`

### Email 4 · Logro

Asunto:

`Ese avance pequeño también cuenta`

Body:

`Si desbloqueaste un logro, úsalo como señal: no se trata de hacerlo perfecto, se trata de construir un hábito que puedas repetir. Puedes compartirlo o simplemente seguir con el siguiente paso.`

CTA:

`Ver mis logros`
