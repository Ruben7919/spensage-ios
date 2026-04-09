# SpendSage Video FAQ Kit

Última actualización: 2026-04-08

## Objetivo

Este kit deja una base repetible para grabar videos verticales del simulador y convertirlos en piezas para:

- YouTube Shorts
- Instagram Reels
- TikTok
- FAQ dentro de soporte o help center

El tono recomendado es:

- directo
- visual
- mobile-first
- con ritmo de creador, no de tutorial corporativo

Target principal:

- 20 a 30 años
- personas que quieren control financiero sin una app pesada
- usuarios que reaccionan mejor a claridad, velocidad y micro-recompensa visual

## Formato recomendado

- Duración por clip: 6 a 12 segundos
- Formato: vertical 9:16
- Apertura: hook fuerte en el primer segundo
- Subtítulos: siempre activos, cortos y fáciles de leer
- Ritmo de edición: jump cuts suaves, punch-in sobre UI clave y un beat ligero

## Estilo visual sugerido

- Fondo musical: lo-fi con beat limpio o house suave
- Sonidos: tap, pop, whoosh, sparkle
- Texto en pantalla: una idea por bloque
- Zooms: cuando aparece una CTA, una cifra o el estado de logro
- Call to action final: "Guárdalo", "Compártelo", "Míralo cuando armes tu mes"

## Piezas incluidas

- Scripts creativos en `/Users/rubenlazaro/Projects/spensage-ios/MarketingAssets/faq-videos/scripts`
- Scripts creativos batch 2 en `/Users/rubenlazaro/Projects/spensage-ios/MarketingAssets/faq-videos/scripts-batch2`
- Scripts creativos batch 3 en `/Users/rubenlazaro/Projects/spensage-ios/MarketingAssets/faq-videos/scripts-batch3`
- Subtítulos `.srt` en `/Users/rubenlazaro/Projects/spensage-ios/MarketingAssets/faq-videos/subtitles`
- Subtítulos batch 2 en `/Users/rubenlazaro/Projects/spensage-ios/MarketingAssets/faq-videos/subtitles-batch2`
- Subtítulos batch 3 en `/Users/rubenlazaro/Projects/spensage-ios/MarketingAssets/faq-videos/subtitles-batch3`
- Grabador de clips del simulador en `/Users/rubenlazaro/Projects/spensage-ios/scripts/video/record_faq_clips.sh`
- Capturador de stills batch 2 en `/Users/rubenlazaro/Projects/spensage-ios/scripts/video/capture_faq_batch2_stills.sh`
- Capturador de stills batch 3 en `/Users/rubenlazaro/Projects/spensage-ios/scripts/video/capture_faq_batch3_stills.sh`
- Clips raw en `/Users/rubenlazaro/Projects/spensage-ios/MarketingAssets/faq-videos/raw`
- Exports de social en `/Users/rubenlazaro/Projects/spensage-ios/MarketingAssets/faq-videos/exported`

## Videos propuestos

### 1. Registra un gasto en segundos

Mensaje:

- la app no te obliga a navegar diez pantallas
- capturas primero y piensas después

Hook sugerido:

- "Si registrar un gasto te toma más de 10 segundos, esa app va tarde."

### 2. Escanea un recibo sin escribir todo

Mensaje:

- el escaneo acelera el borrador
- el usuario mantiene el control antes de guardar

Hook sugerido:

- "No copies el recibo a mano. Revísalo y listo."

### 3. Lee tu análisis sin perderte

Mensaje:

- el gráfico sirve para detectar el bloque exacto
- no hace falta abrir reportes pesados

Hook sugerido:

- "Tu análisis no debería sentirse como Excel con castigo."

### 4. Comparte tu logro cuando subes de nivel

Mensaje:

- la app celebra progreso real
- el share social existe y funciona como contenido orgánico

Hook sugerido:

- "Sí, también puedes presumir que vas mejor con tu dinero."

## Cómo grabar

1. Ten una build debug del app instalada en Simulator.
2. Usa el script:

```bash
/Users/rubenlazaro/Projects/spensage-ios/scripts/video/record_faq_clips.sh record all
```

3. Si quieres exportar a un contenedor más cómodo para edición:

```bash
/Users/rubenlazaro/Projects/spensage-ios/scripts/video/record_faq_clips.sh export all
```

4. Para sacar la pieza final estilo social con hook, subtítulos quemados y CTA:

```bash
/Users/rubenlazaro/Projects/spensage-ios/scripts/video/render_faq_social.sh render all
```

5. Si quieres meter música de fondo:

```bash
/Users/rubenlazaro/Projects/spensage-ios/scripts/video/render_faq_social.sh render faq_04_comparte_logro /ruta/a/music.m4a
```

6. Para generar la segunda tanda basada en estados estables por screenshot:

```bash
/Users/rubenlazaro/Projects/spensage-ios/scripts/video/capture_faq_batch2_stills.sh
/Users/rubenlazaro/Projects/spensage-ios/scripts/video/render_faq_social.sh render faq_05_onboarding_rapido
/Users/rubenlazaro/Projects/spensage-ios/scripts/video/render_faq_social.sh render faq_06_presupuesto_guiado
/Users/rubenlazaro/Projects/spensage-ios/scripts/video/render_faq_social.sh render faq_07_premium_claro
/Users/rubenlazaro/Projects/spensage-ios/scripts/video/render_faq_social.sh render faq_08_soporte_ayuda
```

7. Para generar la tercera tanda basada en estados estables por screenshot:

```bash
/Users/rubenlazaro/Projects/spensage-ios/scripts/video/capture_faq_batch3_stills.sh
/Users/rubenlazaro/Projects/spensage-ios/scripts/video/render_faq_social.sh render faq_09_inicio_con_control
/Users/rubenlazaro/Projects/spensage-ios/scripts/video/render_faq_social.sh render faq_10_cuentas_sin_hojas
/Users/rubenlazaro/Projects/spensage-ios/scripts/video/render_faq_social.sh render faq_11_facturas_sin_sustos
/Users/rubenlazaro/Projects/spensage-ios/scripts/video/render_faq_social.sh render faq_12_reglas_que_ayudan
```

## Notas reales del pipeline

- La grabación sale directa desde `xcrun simctl io recordVideo`.
- La app usa estados de debug para abrir el clip en el punto exacto.
- `ffmpeg` y `ffmpeg-full` ya quedaron instalados localmente en esta Mac.
- El renderizador usa `ffmpeg-full` cuando está disponible, porque ahí viven `drawtext`, `libass`, `freetype` y `fontconfig`.
- El render social usa blur de fondo, layout 9:16, hook superior, subtítulos quemados y CTA inferior.
- Los `.srt` siguen quedando listos si quieres una versión para YouTube o para editar en CapCut, Premiere o Final Cut.

## Recomendación de postproducción

- Mete el clip raw en CapCut o Final Cut.
- Usa el `.srt` correspondiente.
- Añade un punch-in al elemento importante en el segundo 1 o 2.
- Mantén el texto grande, centrado y con contraste alto.
- Si el video va para redes, cierra con una pregunta corta:
  - "¿Quieres que te arme más tutoriales así?"
  - "¿Te subo la parte 2 con presupuesto y metas?"
