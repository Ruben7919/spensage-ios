#!/bin/zsh

set -euo pipefail
unsetopt xtrace verbose
setopt typeset_silent

ROOT="/Users/rubenlazaro/Projects/spensage-ios"
RAW_DIR="$ROOT/MarketingAssets/tutorial-series/raw"
VOICEOVER_DIR="$ROOT/MarketingAssets/launch-campaign/voiceovers"
AUDIO_DIR="$ROOT/MarketingAssets/tutorial-series/audio"
RENDER_DIR="$ROOT/MarketingAssets/launch-campaign/rendered"
PREVIEW_DIR="$ROOT/MarketingAssets/launch-campaign/render-previews"
POSTER_DIR="$ROOT/MarketingAssets/launch-campaign/posters"
POSTER_PREVIEW_DIR="$ROOT/MarketingAssets/launch-campaign/poster-previews"
FFMPEG_FULL_BIN="/opt/homebrew/opt/ffmpeg-full/bin/ffmpeg"
FFPROBE_FULL_BIN="/opt/homebrew/opt/ffmpeg-full/bin/ffprobe"
FFMPEG_BIN="${FFMPEG_BIN:-$([ -x "$FFMPEG_FULL_BIN" ] && echo "$FFMPEG_FULL_BIN" || command -v ffmpeg)}"
FFPROBE_BIN="${FFPROBE_BIN:-$([ -x "$FFPROBE_FULL_BIN" ] && echo "$FFPROBE_FULL_BIN" || command -v ffprobe)}"
FONT_DISPLAY="${FONT_DISPLAY:-/System/Library/Fonts/SFCompactRounded.ttf}"
FONT_BODY="${FONT_BODY:-/System/Library/Fonts/SFNSRounded.ttf}"
ACCENT_COLOR="0x7FE9E1"
SURFACE_COLOR="0x102022"
BED_FILE="$AUDIO_DIR/soft_ambient_bed.m4a"
CHIME_FILE="$AUDIO_DIR/soft_brand_chime.m4a"
VOICE_DELAY_MS="${VOICE_DELAY_MS:-260}"

typeset -a VIDEO_CLIPS=(
    launch_01_main_story
    launch_02_teaser_short
)

typeset -a POSTER_ASSETS=(
    launch_story_01_launch_day
    launch_square_01_announce
    launch_square_02_scan
    launch_square_03_insights
    launch_carousel_01_clarity
    launch_carousel_02_speed
    launch_carousel_03_plan
    launch_carousel_04_share
    sprint3_carousel_01_primer_paso
    sprint3_carousel_02_recibo_sin_drama
    sprint3_carousel_03_dato_util
    sprint3_carousel_04_logro_social
    sprint3_carousel_05_invita
    paid_story_01_caos_a_claro
    paid_story_02_escaneo_control
    paid_story_03_dato_que_ayuda
    paid_story_04_logro_compartible
    paid_story_05_hogar_mas_claro
)

usage() {
    cat <<'EOF'
Usage:
  scripts/video/render_launch_campaign.sh render videos <clip|all>
  scripts/video/render_launch_campaign.sh render posters <asset|all>
  scripts/video/render_launch_campaign.sh render all
  scripts/video/render_launch_campaign.sh list
EOF
}

assert_dependencies() {
    [[ -n "$FFMPEG_BIN" && -x "$FFMPEG_BIN" ]] || { echo "ffmpeg is required." >&2; exit 1; }
    [[ -n "$FFPROBE_BIN" && -x "$FFPROBE_BIN" ]] || { echo "ffprobe is required." >&2; exit 1; }
    [[ -f "$BED_FILE" ]] || { echo "Missing background bed: $BED_FILE" >&2; exit 1; }
    [[ -f "$CHIME_FILE" ]] || { echo "Missing brand chime: $CHIME_FILE" >&2; exit 1; }
    mkdir -p "$RENDER_DIR" "$PREVIEW_DIR" "$POSTER_DIR" "$POSTER_PREVIEW_DIR"
}

media_duration() {
    "$FFPROBE_BIN" -v error -show_entries format=duration -of csv=p=0 "$1"
}

video_config() {
    SEGMENTS=()
    case "$1" in
        launch_01_main_story)
            HOOK_LINE_ONE='Llega MichiFinanzas'
            HOOK_LINE_TWO='menos friccion, mas calma'
            CTA_TEXT='Registra, escanea, entiende y comparte tu avance'
            VOICE_FILE="$VOICEOVER_DIR/launch_01_main_story.m4a"
            PREVIEW_TIME='00:00:06.600'
            SEGMENTS=(
                "$RAW_DIR/tutorial_02_home_y_agregar_gasto.mov|12.40|2.80|Todo empieza claro"
                "$RAW_DIR/tutorial_03_escaneo_y_guardado.mov|10.20|2.80|Escanea con control"
                "$RAW_DIR/tutorial_04_analisis_y_presupuesto.mov|10.40|3.40|Entiende el dato"
                "$RAW_DIR/tutorial_05_cuentas_facturas_reglas.mov|20.20|3.10|Ordena todo en local"
                "$RAW_DIR/tutorial_06_ajustes_ayuda_y_planes.mov|18.20|2.80|Ubicate rapido"
                "$RAW_DIR/tutorial_07_logro_y_share.mov|16.20|2.60|Celebra tu progreso"
            )
            ;;
        launch_02_teaser_short)
            HOOK_LINE_ONE='Tu dinero mas claro'
            HOOK_LINE_TWO='desde el primer dia'
            CTA_TEXT='Launch teaser para Shorts, Reels y YouTube'
            VOICE_FILE="$VOICEOVER_DIR/launch_02_teaser_short.m4a"
            PREVIEW_TIME='00:00:04.100'
            SEGMENTS=(
                "$RAW_DIR/tutorial_02_home_y_agregar_gasto.mov|12.40|2.30|Abre y registra"
                "$RAW_DIR/tutorial_03_escaneo_y_guardado.mov|10.10|2.30|Escanea y confirma"
                "$RAW_DIR/tutorial_04_analisis_y_presupuesto.mov|10.40|2.60|Toca y entiende"
                "$RAW_DIR/tutorial_07_logro_y_share.mov|16.10|2.20|Comparte tu logro"
            )
            ;;
        *)
            echo "Unknown launch clip: $1" >&2
            exit 1
            ;;
    esac
}

poster_config() {
    case "$1" in
        launch_story_01_launch_day)
            SOURCE_FILE="$RAW_DIR/tutorial_02_home_y_agregar_gasto.mov"
            SOURCE_TIME='12.40'
            OUTPUT_WIDTH='1080'
            OUTPUT_HEIGHT='1920'
            PHONE_HEIGHT='1400'
            PHONE_Y='252'
            TOP_BOX_Y='44'
            TOP_BOX_H='144'
            HOOK_LINE_ONE='Ya salio MichiFinanzas'
            HOOK_LINE_TWO='orden con mas calma'
            SUPPORT_LINE_ONE='Registra, escanea y entiende con una app'
            SUPPORT_LINE_TWO='que se siente mas clara desde el primer uso.'
            CTA_TEXT='Disponible para demo y contenido organico'
            ;;
        launch_square_01_announce)
            SOURCE_FILE="$RAW_DIR/tutorial_02_home_y_agregar_gasto.mov"
            SOURCE_TIME='12.40'
            OUTPUT_WIDTH='1080'
            OUTPUT_HEIGHT='1080'
            PHONE_HEIGHT='680'
            PHONE_Y='162'
            TOP_BOX_Y='34'
            TOP_BOX_H='126'
            HOOK_LINE_ONE='Ordena tu dinero'
            HOOK_LINE_TWO='sin pelear con la app'
            SUPPORT_LINE_ONE='MichiFinanzas te ayuda a registrar y volver'
            SUPPORT_LINE_TWO='sin sentir que abriste otra tarea pesada.'
            CTA_TEXT='Lanzamiento social / post cuadrado'
            ;;
        launch_square_02_scan)
            SOURCE_FILE="$RAW_DIR/tutorial_03_escaneo_y_guardado.mov"
            SOURCE_TIME='10.10'
            OUTPUT_WIDTH='1080'
            OUTPUT_HEIGHT='1080'
            PHONE_HEIGHT='680'
            PHONE_Y='162'
            TOP_BOX_Y='34'
            TOP_BOX_H='126'
            HOOK_LINE_ONE='Escanea y revisa'
            HOOK_LINE_TWO='antes de guardar'
            SUPPORT_LINE_ONE='Velocidad con control real.'
            SUPPORT_LINE_TWO='La ultima decision sigue siendo tuya.'
            CTA_TEXT='Feature highlight / OCR asistido'
            ;;
        launch_square_03_insights)
            SOURCE_FILE="$RAW_DIR/tutorial_04_analisis_y_presupuesto.mov"
            SOURCE_TIME='10.40'
            OUTPUT_WIDTH='1080'
            OUTPUT_HEIGHT='1080'
            PHONE_HEIGHT='680'
            PHONE_Y='162'
            TOP_BOX_Y='34'
            TOP_BOX_H='126'
            HOOK_LINE_ONE='Toca el dato'
            HOOK_LINE_TWO='y arma el plan'
            SUPPORT_LINE_ONE='Los insights no se quedan en un grafico.'
            SUPPORT_LINE_TWO='Te ayudan a decidir que hacer despues.'
            CTA_TEXT='Feature highlight / analisis claro'
            ;;
        launch_carousel_01_clarity)
            SOURCE_FILE="$RAW_DIR/tutorial_01_onboarding_first_win.mov"
            SOURCE_TIME='9.20'
            OUTPUT_WIDTH='1080'
            OUTPUT_HEIGHT='1350'
            PHONE_HEIGHT='930'
            PHONE_Y='176'
            TOP_BOX_Y='34'
            TOP_BOX_H='132'
            HOOK_LINE_ONE='1. Empieza claro'
            HOOK_LINE_TWO='y sin ruido'
            SUPPORT_LINE_ONE='Onboarding corto para que veas'
            SUPPORT_LINE_TWO='un numero util desde el inicio.'
            CTA_TEXT='Carousel launch / slide 1'
            ;;
        launch_carousel_02_speed)
            SOURCE_FILE="$RAW_DIR/tutorial_03_escaneo_y_guardado.mov"
            SOURCE_TIME='10.10'
            OUTPUT_WIDTH='1080'
            OUTPUT_HEIGHT='1350'
            PHONE_HEIGHT='930'
            PHONE_Y='176'
            TOP_BOX_Y='34'
            TOP_BOX_H='132'
            HOOK_LINE_ONE='2. Hazlo rapido'
            HOOK_LINE_TWO='sin perder control'
            SUPPORT_LINE_ONE='Escanear o registrar no deberia'
            SUPPORT_LINE_TWO='hacerte revisar diez veces lo mismo.'
            CTA_TEXT='Carousel launch / slide 2'
            ;;
        launch_carousel_03_plan)
            SOURCE_FILE="$RAW_DIR/tutorial_04_analisis_y_presupuesto.mov"
            SOURCE_TIME='10.40'
            OUTPUT_WIDTH='1080'
            OUTPUT_HEIGHT='1350'
            PHONE_HEIGHT='930'
            PHONE_Y='176'
            TOP_BOX_Y='34'
            TOP_BOX_H='132'
            HOOK_LINE_ONE='3. Mira y decide'
            HOOK_LINE_TWO='con mas calma'
            SUPPORT_LINE_ONE='Toca una barra, mira el valor'
            SUPPORT_LINE_TWO='y convierte ese dato en accion.'
            CTA_TEXT='Carousel launch / slide 3'
            ;;
        launch_carousel_04_share)
            SOURCE_FILE="$RAW_DIR/tutorial_07_logro_y_share.mov"
            SOURCE_TIME='16.10'
            OUTPUT_WIDTH='1080'
            OUTPUT_HEIGHT='1350'
            PHONE_HEIGHT='930'
            PHONE_Y='176'
            TOP_BOX_Y='34'
            TOP_BOX_H='132'
            HOOK_LINE_ONE='4. Celebra el avance'
            HOOK_LINE_TWO='y compartelo'
            SUPPORT_LINE_ONE='Cuando mejoras con tu dinero,'
            SUPPORT_LINE_TWO='tambien vale mostrar ese logro.'
            CTA_TEXT='Carousel launch / slide 4'
            ;;
        sprint3_carousel_01_primer_paso)
            SOURCE_FILE="$RAW_DIR/tutorial_02_home_y_agregar_gasto.mov"
            SOURCE_TIME='12.40'
            OUTPUT_WIDTH='1080'
            OUTPUT_HEIGHT='1350'
            PHONE_HEIGHT='930'
            PHONE_Y='176'
            TOP_BOX_Y='34'
            TOP_BOX_H='132'
            HOOK_LINE_ONE='Primero guarda'
            HOOK_LINE_TWO='una compra real'
            SUPPORT_LINE_ONE='No hace falta ordenar todo hoy.'
            SUPPORT_LINE_TWO='Empieza con un dato que sí pasó.'
            CTA_TEXT='Sprint 3 / carousel 1'
            ;;
        sprint3_carousel_02_recibo_sin_drama)
            SOURCE_FILE="$RAW_DIR/tutorial_03_escaneo_y_guardado.mov"
            SOURCE_TIME='10.10'
            OUTPUT_WIDTH='1080'
            OUTPUT_HEIGHT='1350'
            PHONE_HEIGHT='930'
            PHONE_Y='176'
            TOP_BOX_Y='34'
            TOP_BOX_H='132'
            HOOK_LINE_ONE='El recibo'
            HOOK_LINE_TWO='sin drama'
            SUPPORT_LINE_ONE='Foto, revisa y guarda.'
            SUPPORT_LINE_TWO='Rápido, pero con control tuyo.'
            CTA_TEXT='Sprint 3 / carousel 2'
            ;;
        sprint3_carousel_03_dato_util)
            SOURCE_FILE="$RAW_DIR/tutorial_04_analisis_y_presupuesto.mov"
            SOURCE_TIME='13.00'
            OUTPUT_WIDTH='1080'
            OUTPUT_HEIGHT='1350'
            PHONE_HEIGHT='930'
            PHONE_Y='176'
            TOP_BOX_Y='34'
            TOP_BOX_H='132'
            HOOK_LINE_ONE='Toca el dato'
            HOOK_LINE_TWO='y decide'
            SUPPORT_LINE_ONE='Una barra no debería ser ruido.'
            SUPPORT_LINE_TWO='Debe ayudarte a dar el siguiente paso.'
            CTA_TEXT='Sprint 3 / carousel 3'
            ;;
        sprint3_carousel_04_logro_social)
            SOURCE_FILE="$RAW_DIR/tutorial_07_logro_y_share.mov"
            SOURCE_TIME='16.10'
            OUTPUT_WIDTH='1080'
            OUTPUT_HEIGHT='1350'
            PHONE_HEIGHT='930'
            PHONE_Y='176'
            TOP_BOX_Y='34'
            TOP_BOX_H='132'
            HOOK_LINE_ONE='Celebra'
            HOOK_LINE_TWO='tu avance'
            SUPPORT_LINE_ONE='No tiene que ser perfecto.'
            SUPPORT_LINE_TWO='Si hoy avanzaste, también cuenta.'
            CTA_TEXT='Sprint 3 / carousel 4'
            ;;
        sprint3_carousel_05_invita)
            SOURCE_FILE="$RAW_DIR/tutorial_07_logro_y_share.mov"
            SOURCE_TIME='18.40'
            OUTPUT_WIDTH='1080'
            OUTPUT_HEIGHT='1350'
            PHONE_HEIGHT='930'
            PHONE_Y='176'
            TOP_BOX_Y='34'
            TOP_BOX_H='132'
            HOOK_LINE_ONE='Invita después'
            HOOK_LINE_TWO='de probarlo'
            SUPPORT_LINE_ONE='Comparte cuando ya te sirvió.'
            SUPPORT_LINE_TWO='Referral medible, sin presión.'
            CTA_TEXT='Sprint 3 / carousel 5'
            ;;
        paid_story_01_caos_a_claro)
            SOURCE_FILE="$RAW_DIR/tutorial_02_home_y_agregar_gasto.mov"
            SOURCE_TIME='12.40'
            OUTPUT_WIDTH='1080'
            OUTPUT_HEIGHT='1920'
            PHONE_HEIGHT='1360'
            PHONE_Y='258'
            TOP_BOX_Y='48'
            TOP_BOX_H='146'
            HOOK_LINE_ONE='Gastos en'
            HOOK_LINE_TWO='la cabeza?'
            SUPPORT_LINE_ONE='Empieza con una compra real.'
            SUPPORT_LINE_TWO='MichiFinanzas te ayuda a ordenar el primer paso.'
            CTA_TEXT='Paid test 01 / caos a claridad'
            ;;
        paid_story_02_escaneo_control)
            SOURCE_FILE="$RAW_DIR/tutorial_03_escaneo_y_guardado.mov"
            SOURCE_TIME='10.10'
            OUTPUT_WIDTH='1080'
            OUTPUT_HEIGHT='1920'
            PHONE_HEIGHT='1360'
            PHONE_Y='258'
            TOP_BOX_Y='48'
            TOP_BOX_H='146'
            HOOK_LINE_ONE='Foto, revisa'
            HOOK_LINE_TWO='y guarda'
            SUPPORT_LINE_ONE='Rapido no tiene que significar automatico.'
            SUPPORT_LINE_TWO='Tu revisas antes de guardar.'
            CTA_TEXT='Paid test 02 / escaneo con control'
            ;;
        paid_story_03_dato_que_ayuda)
            SOURCE_FILE="$RAW_DIR/tutorial_04_analisis_y_presupuesto.mov"
            SOURCE_TIME='13.00'
            OUTPUT_WIDTH='1080'
            OUTPUT_HEIGHT='1920'
            PHONE_HEIGHT='1360'
            PHONE_Y='258'
            TOP_BOX_Y='48'
            TOP_BOX_H='146'
            HOOK_LINE_ONE='Tu grafico'
            HOOK_LINE_TWO='si te habla'
            SUPPORT_LINE_ONE='Toca, mira el valor y decide.'
            SUPPORT_LINE_TWO='Menos reporte, mas siguiente paso.'
            CTA_TEXT='Paid test 03 / dato que ayuda'
            ;;
        paid_story_04_logro_compartible)
            SOURCE_FILE="$RAW_DIR/tutorial_07_logro_y_share.mov"
            SOURCE_TIME='16.10'
            OUTPUT_WIDTH='1080'
            OUTPUT_HEIGHT='1920'
            PHONE_HEIGHT='1360'
            PHONE_Y='258'
            TOP_BOX_Y='48'
            TOP_BOX_H='146'
            HOOK_LINE_ONE='Celebra'
            HOOK_LINE_TWO='lo pequeno'
            SUPPORT_LINE_ONE='Un avance financiero tambien cuenta.'
            SUPPORT_LINE_TWO='Compartelo si te dio orgullo.'
            CTA_TEXT='Paid test 04 / logro compartible'
            ;;
        paid_story_05_hogar_mas_claro)
            SOURCE_FILE="$RAW_DIR/tutorial_05_cuentas_facturas_reglas.mov"
            SOURCE_TIME='21.00'
            OUTPUT_WIDTH='1080'
            OUTPUT_HEIGHT='1920'
            PHONE_HEIGHT='1360'
            PHONE_Y='258'
            TOP_BOX_Y='48'
            TOP_BOX_H='146'
            HOOK_LINE_ONE='Tu hogar'
            HOOK_LINE_TWO='mas claro'
            SUPPORT_LINE_ONE='Cuentas, reglas y facturas en una ruta.'
            SUPPORT_LINE_TWO='Vuelve cuando lo necesites.'
            CTA_TEXT='Paid test 05 / hogar mas claro'
            ;;
        *)
            echo "Unknown poster asset: $1" >&2
            exit 1
            ;;
    esac
}

render_video_clip() {
    local clip="$1"
    local output="$RENDER_DIR/${clip}.mp4"
    local preview="$PREVIEW_DIR/${clip}.png"
    local tmpdir
    local hook_one_file
    local hook_two_file
    local cta_file
    local -a input_args=()
    local -a segment_timings=()
    local -a segment_label_files=()
    local filter_complex=""
    local concat_inputs=""
    local segment_index=0
    local total_duration='0.000'
    local fade_out_start
    local voice_duration
    local available_voice_window
    local tempo
    local music_index
    local voice_index
    local chime_index

    video_config "$clip"
    [[ -f "$VOICE_FILE" ]] || { echo "Missing launch voiceover: $VOICE_FILE" >&2; exit 1; }

    tmpdir="$(mktemp -d)"
    hook_one_file="$tmpdir/hook_one.txt"
    hook_two_file="$tmpdir/hook_two.txt"
    cta_file="$tmpdir/cta.txt"

    printf '%s' "$HOOK_LINE_ONE" > "$hook_one_file"
    printf '%s' "$HOOK_LINE_TWO" > "$hook_two_file"
    printf '%s' "$CTA_TEXT" > "$cta_file"

    local spec
    for spec in "${SEGMENTS[@]}"; do
        local source_file
        local start_time
        local duration
        local label
        local label_file
        local current_start
        local current_end

        IFS='|' read -r source_file start_time duration label <<< "$spec"
        [[ -f "$source_file" ]] || { echo "Missing source video: $source_file" >&2; exit 1; }

        input_args+=(-i "$source_file")
        filter_complex+="[$segment_index:v]trim=start=${start_time}:duration=${duration},setpts=PTS-STARTPTS,fps=30,scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920[seg${segment_index}];"
        concat_inputs+="[seg${segment_index}]"

        current_start="$total_duration"
        total_duration="$(awk -v current="$total_duration" -v add="$duration" 'BEGIN { printf "%.3f", current + add }')"
        current_end="$total_duration"
        segment_timings+=("${current_start}|${current_end}")

        label_file="$tmpdir/segment_label_${segment_index}.txt"
        printf '%s' "$label" > "$label_file"
        segment_label_files+=("$label_file")

        segment_index=$((segment_index + 1))
    done

    fade_out_start="$(awk -v total="$total_duration" 'BEGIN { value = total - 0.40; if (value < 0) value = 0; printf "%.3f", value }')"
    voice_duration="$(media_duration "$VOICE_FILE")"
    available_voice_window="$(awk -v total="$total_duration" -v delay="$VOICE_DELAY_MS" 'BEGIN { value = total - (delay / 1000.0) - 0.35; if (value < 1.0) value = 1.0; printf "%.3f", value }')"
    tempo="$(awk -v voice="$voice_duration" -v available="$available_voice_window" 'BEGIN { value = voice / available; if (value < 1.0) value = 1.0; if (value > 1.20) value = 1.20; printf "%.3f", value }')"

    music_index="$segment_index"
    voice_index=$((segment_index + 1))
    chime_index=$((segment_index + 2))
    input_args+=(-stream_loop -1 -i "$BED_FILE" -i "$VOICE_FILE" -i "$CHIME_FILE")

    filter_complex+="${concat_inputs}concat=n=${#SEGMENTS[@]}:v=1:a=0[base];"
    filter_complex+="[base]drawbox=x=34:y=40:w=622:h=134:color=${SURFACE_COLOR}@0.36:t=fill,"
    filter_complex+="drawbox=x=28:y=54:w=6:h=84:color=${ACCENT_COLOR}@0.96:t=fill,"
    filter_complex+="drawtext=fontfile='${FONT_DISPLAY}':textfile='${hook_one_file}':reload=1:fontcolor=white:fontsize=52:shadowcolor=0x081214@0.44:shadowx=0:shadowy=4:x=50:y=54,"
    filter_complex+="drawtext=fontfile='${FONT_DISPLAY}':textfile='${hook_two_file}':reload=1:fontcolor=white:fontsize=52:shadowcolor=0x081214@0.44:shadowx=0:shadowy=4:x=50:y=104,"
    filter_complex+="drawbox=x=846:y=54:w=168:h=44:color=${SURFACE_COLOR}@0.34:t=fill,"
    filter_complex+="drawtext=fontfile='${FONT_BODY}':text='MichiFinanzas':fontcolor=${ACCENT_COLOR}:fontsize=22:x=846:y=64,"

    local timing
    local timing_index=1
    for timing in "${segment_timings[@]}"; do
        local start_mark
        local end_mark
        local label_path="${segment_label_files[$timing_index]}"
        IFS='|' read -r start_mark end_mark <<< "$timing"
        filter_complex+="drawbox=x=316:y=1590:w=448:h=66:color=${SURFACE_COLOR}@0.38:t=fill:enable='between(t,${start_mark},${end_mark})',"
        filter_complex+="drawtext=fontfile='${FONT_BODY}':textfile='${label_path}':reload=1:fontcolor=${ACCENT_COLOR}:fontsize=28:shadowcolor=0x081214@0.42:shadowx=0:shadowy=3:x=(w-text_w)/2:y=1609:enable='between(t,${start_mark},${end_mark})',"
        timing_index=$((timing_index + 1))
    done

    filter_complex+="drawbox=x=162:y=1814:w=756:h=54:color=${SURFACE_COLOR}@0.34:t=fill,"
    filter_complex+="drawtext=fontfile='${FONT_BODY}':textfile='${cta_file}':reload=1:fontcolor=white:fontsize=24:x=(w-text_w)/2:y=1828,"
    filter_complex+="fade=t=out:st=${fade_out_start}:d=0.40[v];"
    filter_complex+="[${music_index}:a]atrim=0:${total_duration},volume=0.11,afade=t=in:st=0:d=0.6,afade=t=out:st=${fade_out_start}:d=0.55[music];"
    filter_complex+="[${voice_index}:a]aformat=sample_fmts=fltp:sample_rates=48000:channel_layouts=stereo,atempo=${tempo},adelay=${VOICE_DELAY_MS}|${VOICE_DELAY_MS},volume=1.26,acompressor=threshold=0.10:ratio=2.8:attack=12:release=180,asplit=2[voice_sidechain][voice_mix];"
    filter_complex+="[${chime_index}:a]atrim=0:1.0,adelay=120|120,volume=0.14[chime];"
    filter_complex+="[music][voice_sidechain]sidechaincompress=threshold=0.025:ratio=9:attack=18:release=280[ducked];"
    filter_complex+="[ducked][voice_mix][chime]amix=inputs=3:normalize=0:weights='1 1 0.75',loudnorm=I=-16:LRA=10:TP=-1.5[a]"

    "$FFMPEG_BIN" -y \
        "${input_args[@]}" \
        -filter_complex "$filter_complex" \
        -map "[v]" \
        -map "[a]" \
        -r 30 \
        -c:v libx264 \
        -preset medium \
        -crf 20 \
        -pix_fmt yuv420p \
        -c:a aac \
        -b:a 192k \
        -movflags +faststart \
        "$output"

    "$FFMPEG_BIN" -y -ss "${PREVIEW_TIME}" -i "$output" -frames:v 1 "$preview" >/dev/null 2>&1
    rm -rf "$tmpdir"
    echo "Rendered $output"
}

extract_still() {
    local source_file="$1"
    local timestamp="$2"
    local output="$3"
    "$FFMPEG_BIN" -y -ss "$timestamp" -i "$source_file" -frames:v 1 "$output" >/dev/null 2>&1
}

render_poster_asset() {
    local asset="$1"
    local output="$POSTER_DIR/${asset}.png"
    local preview="$POSTER_PREVIEW_DIR/${asset}.png"
    local tmpdir
    local still_file
    local hook_one_file
    local hook_two_file
    local support_one_file
    local support_two_file
    local cta_file
    local support_box_y
    local support_box_h='120'
    local support_line_one_y
    local support_line_two_y
    local cta_box_y
    local cta_box_h='60'
    local phone_width
    local phone_x
    local shadow_w
    local shadow_x

    poster_config "$asset"

    tmpdir="$(mktemp -d)"
    still_file="$tmpdir/source.png"
    hook_one_file="$tmpdir/hook_one.txt"
    hook_two_file="$tmpdir/hook_two.txt"
    support_one_file="$tmpdir/support_one.txt"
    support_two_file="$tmpdir/support_two.txt"
    cta_file="$tmpdir/cta.txt"

    extract_still "$SOURCE_FILE" "$SOURCE_TIME" "$still_file"

    printf '%s' "$HOOK_LINE_ONE" > "$hook_one_file"
    printf '%s' "$HOOK_LINE_TWO" > "$hook_two_file"
    printf '%s' "$SUPPORT_LINE_ONE" > "$support_one_file"
    printf '%s' "$SUPPORT_LINE_TWO" > "$support_two_file"
    printf '%s' "$CTA_TEXT" > "$cta_file"

    support_box_y="$(awk -v height="$OUTPUT_HEIGHT" 'BEGIN { printf "%d", height - 224 }')"
    support_line_one_y="$(awk -v y="$support_box_y" 'BEGIN { printf "%d", y + 22 }')"
    support_line_two_y="$(awk -v y="$support_box_y" 'BEGIN { printf "%d", y + 58 }')"
    cta_box_y="$(awk -v height="$OUTPUT_HEIGHT" 'BEGIN { printf "%d", height - 78 }')"
    phone_width="$(awk -v height="$PHONE_HEIGHT" 'BEGIN { printf "%d", (1206.0 / 2622.0) * height }')"
    phone_x="$(awk -v width="$OUTPUT_WIDTH" -v phone="$phone_width" 'BEGIN { printf "%d", (width - phone) / 2 }')"
    shadow_w="$(awk -v phone="$phone_width" 'BEGIN { printf "%d", phone + 34 }')"
    shadow_x="$(awk -v x="$phone_x" 'BEGIN { printf "%d", x - 17 }')"

    "$FFMPEG_BIN" -y \
        -i "$still_file" \
        -filter_complex "\
[0:v]scale=${OUTPUT_WIDTH}:${OUTPUT_HEIGHT}:force_original_aspect_ratio=increase,crop=${OUTPUT_WIDTH}:${OUTPUT_HEIGHT},gblur=sigma=28,eq=brightness=-0.08:saturation=1.08[bg];\
[0:v]scale=-1:${PHONE_HEIGHT}:flags=lanczos[phone];\
[bg]drawbox=x=0:y=0:w=${OUTPUT_WIDTH}:h=${OUTPUT_HEIGHT}:color=0xE8F6F4@0.10:t=fill,\
drawbox=x=0:y=0:w=${OUTPUT_WIDTH}:h=${OUTPUT_HEIGHT}:color=${ACCENT_COLOR}@0.03:t=fill[bgfill];\
[bgfill]drawbox=x=${shadow_x}:y=${PHONE_Y}:w=${shadow_w}:h=${PHONE_HEIGHT}:color=black@0.18:t=fill[shadow];\
[shadow][phone]overlay=x=(W-w)/2:y=${PHONE_Y}[base];\
[base]drawbox=x=36:y=${TOP_BOX_Y}:w=648:h=${TOP_BOX_H}:color=${SURFACE_COLOR}@0.38:t=fill,\
drawbox=x=30:y=$((${TOP_BOX_Y}+14)):w=6:h=92:color=${ACCENT_COLOR}@0.96:t=fill,\
drawtext=fontfile='${FONT_DISPLAY}':textfile='${hook_one_file}':reload=1:fontcolor=white:fontsize=50:shadowcolor=0x081214@0.44:shadowx=0:shadowy=4:x=52:y=$((${TOP_BOX_Y}+16)),\
drawtext=fontfile='${FONT_DISPLAY}':textfile='${hook_two_file}':reload=1:fontcolor=white:fontsize=50:shadowcolor=0x081214@0.44:shadowx=0:shadowy=4:x=52:y=$((${TOP_BOX_Y}+68)),\
drawbox=x=$((${OUTPUT_WIDTH}-214)):y=$((${TOP_BOX_Y}+14)):w=170:h=40:color=${SURFACE_COLOR}@0.34:t=fill,\
drawtext=fontfile='${FONT_BODY}':text='MichiFinanzas':fontcolor=${ACCENT_COLOR}:fontsize=22:x=$((${OUTPUT_WIDTH}-228)):y=$((${TOP_BOX_Y}+22)),\
drawbox=x=104:y=${support_box_y}:w=$((${OUTPUT_WIDTH}-208)):h=${support_box_h}:color=${SURFACE_COLOR}@0.40:t=fill,\
drawtext=fontfile='${FONT_BODY}':textfile='${support_one_file}':reload=1:fontcolor=white:fontsize=30:shadowcolor=0x081214@0.40:shadowx=0:shadowy=3:x=(w-text_w)/2:y=${support_line_one_y},\
drawtext=fontfile='${FONT_BODY}':textfile='${support_two_file}':reload=1:fontcolor=white:fontsize=30:shadowcolor=0x081214@0.40:shadowx=0:shadowy=3:x=(w-text_w)/2:y=${support_line_two_y},\
drawbox=x=176:y=${cta_box_y}:w=$((${OUTPUT_WIDTH}-352)):h=${cta_box_h}:color=${SURFACE_COLOR}@0.34:t=fill,\
drawtext=fontfile='${FONT_BODY}':textfile='${cta_file}':reload=1:fontcolor=${ACCENT_COLOR}:fontsize=22:x=(w-text_w)/2:y=$((${cta_box_y}+16))[v]" \
        -map "[v]" \
        -frames:v 1 \
        -update 1 \
        "$output"

    cp "$output" "$preview"
    rm -rf "$tmpdir"
    echo "Rendered $output"
}

render_all_videos() {
    local clip
    for clip in "${VIDEO_CLIPS[@]}"; do
        render_video_clip "$clip"
    done
}

render_all_posters() {
    local asset
    for asset in "${POSTER_ASSETS[@]}"; do
        render_poster_asset "$asset"
    done
}

main() {
    local action="${1:-}"
    local kind="${2:-}"
    local target="${3:-}"

    assert_dependencies

    case "$action" in
        list)
            echo "Videos:"
            printf '  %s\n' "${VIDEO_CLIPS[@]}"
            echo "Posters:"
            printf '  %s\n' "${POSTER_ASSETS[@]}"
            ;;
        render)
            case "$kind" in
                all)
                    render_all_videos
                    render_all_posters
                    ;;
                videos)
                    [[ -n "$target" ]] || { usage; exit 1; }
                    if [[ "$target" == "all" ]]; then
                        render_all_videos
                    else
                        render_video_clip "$target"
                    fi
                    ;;
                posters)
                    [[ -n "$target" ]] || { usage; exit 1; }
                    if [[ "$target" == "all" ]]; then
                        render_all_posters
                    else
                        render_poster_asset "$target"
                    fi
                    ;;
                *)
                    usage
                    exit 1
                    ;;
            esac
            ;;
        *)
            usage
            exit 1
            ;;
    esac
}

main "$@"
