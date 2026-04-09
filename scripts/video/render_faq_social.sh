#!/bin/zsh

set -euo pipefail

ROOT="/Users/rubenlazaro/Projects/spensage-ios"
RAW_DIR="$ROOT/MarketingAssets/faq-videos/raw"
SUBTITLE_DIR="$ROOT/MarketingAssets/faq-videos/subtitles"
SUBTITLE_BATCH2_DIR="$ROOT/MarketingAssets/faq-videos/subtitles-batch2"
SUBTITLE_BATCH3_DIR="$ROOT/MarketingAssets/faq-videos/subtitles-batch3"
RENDER_DIR="$ROOT/MarketingAssets/faq-videos/rendered"
PREVIEW_DIR="$ROOT/MarketingAssets/faq-videos/render-previews"
STILLS_BATCH2_DIR="$ROOT/MarketingAssets/faq-videos/stills-batch2"
STILLS_BATCH3_DIR="$ROOT/MarketingAssets/faq-videos/stills-batch3"
FFMPEG_FULL_BIN="/opt/homebrew/opt/ffmpeg-full/bin/ffmpeg"
FFPROBE_FULL_BIN="/opt/homebrew/opt/ffmpeg-full/bin/ffprobe"
FFMPEG_BIN="${FFMPEG_BIN:-$([ -x "$FFMPEG_FULL_BIN" ] && echo "$FFMPEG_FULL_BIN" || command -v ffmpeg)}"
FFPROBE_BIN="${FFPROBE_BIN:-$([ -x "$FFPROBE_FULL_BIN" ] && echo "$FFPROBE_FULL_BIN" || command -v ffprobe)}"
FONT_DISPLAY="${FONT_DISPLAY:-/System/Library/Fonts/SFNSRounded.ttf}"
FONT_BODY="${FONT_BODY:-/System/Library/Fonts/SFNS.ttf}"
ACCENT_COLOR="0x7FE9E1"
SURFACE_COLOR="0x0D1718"

mkdir -p "$RENDER_DIR" "$PREVIEW_DIR"

typeset -a ALL_CLIPS=(
    faq_01_registra_gasto
    faq_02_escanea_recibo
    faq_03_lee_analisis
    faq_04_comparte_logro
    faq_05_onboarding_rapido
    faq_06_presupuesto_guiado
    faq_07_premium_claro
    faq_08_soporte_ayuda
    faq_09_inicio_con_control
    faq_10_cuentas_sin_hojas
    faq_11_facturas_sin_sustos
    faq_12_reglas_que_ayudan
)

usage() {
    cat <<'EOF'
Usage:
  scripts/video/render_faq_social.sh render <clip|all> [music_file]
  scripts/video/render_faq_social.sh list

Examples:
  scripts/video/render_faq_social.sh render all
  scripts/video/render_faq_social.sh render faq_04_comparte_logro /path/to/music.m4a
EOF
}

clip_config() {
    case "$1" in
        faq_01_registra_gasto)
            HOOK_LINE_ONE='Gasto rápido,'
            HOOK_LINE_TWO='sin drama'
            CTA_TEXT='Guárdalo para tu próximo gasto'
            SLOW_FACTOR='2.50'
            ;;
        faq_02_escanea_recibo)
            HOOK_LINE_ONE='Escanea,'
            HOOK_LINE_TWO='revisa y guarda'
            CTA_TEXT='Más rápido que copiar todo a mano'
            SLOW_FACTOR='6.10'
            ;;
        faq_03_lee_analisis)
            HOOK_LINE_ONE='Toca una barra'
            HOOK_LINE_TWO='y entiende el dato'
            CTA_TEXT='Parte 2: tendencia y categorías'
            SLOW_FACTOR='3.60'
            ;;
        faq_04_comparte_logro)
            HOOK_LINE_ONE='Tu progreso'
            HOOK_LINE_TWO='también se comparte'
            CTA_TEXT='Ideal para historias, reels y chat'
            SLOW_FACTOR='2.30'
            ;;
        faq_05_onboarding_rapido)
            HOOK_LINE_ONE='Tu primer win'
            HOOK_LINE_TWO='en 3 pasos'
            CTA_TEXT='Ideal para atraer usuarios nuevos'
            SLOW_FACTOR='1.00'
            ;;
        faq_06_presupuesto_guiado)
            HOOK_LINE_ONE='Presupuesto'
            HOOK_LINE_TWO='que sí se usa'
            CTA_TEXT='Compártelo con quien vive en caos'
            SLOW_FACTOR='1.00'
            ;;
        faq_07_premium_claro)
            HOOK_LINE_ONE='Planes claros,'
            HOOK_LINE_TWO='decisiones rápidas'
            CTA_TEXT='Premium tiene que explicarse solo'
            SLOW_FACTOR='1.00'
            ;;
        faq_08_soporte_ayuda)
            HOOK_LINE_ONE='Ayuda'
            HOOK_LINE_TWO='sin vueltas'
            CTA_TEXT='Soporte claro también vende confianza'
            SLOW_FACTOR='1.00'
            ;;
        faq_09_inicio_con_control)
            HOOK_LINE_ONE='Inicio con'
            HOOK_LINE_TWO='contexto real'
            CTA_TEXT='Un buen home hace que vuelvas manana'
            SLOW_FACTOR='1.00'
            ;;
        faq_10_cuentas_sin_hojas)
            HOOK_LINE_ONE='Cuentas sin'
            HOOK_LINE_TWO='hojas sueltas'
            CTA_TEXT='Ver todo junto baja mucha ansiedad'
            SLOW_FACTOR='1.00'
            ;;
        faq_11_facturas_sin_sustos)
            HOOK_LINE_ONE='Facturas sin'
            HOOK_LINE_TWO='micro-sustos'
            CTA_TEXT='Verlo antes siempre sale mas barato'
            SLOW_FACTOR='1.00'
            ;;
        faq_12_reglas_que_ayudan)
            HOOK_LINE_ONE='Reglas que'
            HOOK_LINE_TWO='si ayudan'
            CTA_TEXT='Automatizar bien tiene que sentirse ligero'
            SLOW_FACTOR='1.00'
            ;;
        *)
            echo "Unknown clip: $1" >&2
            exit 1
            ;;
    esac
}

assert_dependencies() {
    [[ -n "$FFMPEG_BIN" && -x "$FFMPEG_BIN" ]] || {
        echo "ffmpeg is required." >&2
        exit 1
    }
    [[ -n "$FFPROBE_BIN" && -x "$FFPROBE_BIN" ]] || {
        echo "ffprobe is required." >&2
        exit 1
    }
    [[ -f "$FONT_DISPLAY" ]] || {
        echo "Missing display font: $FONT_DISPLAY" >&2
        exit 1
    }
    [[ -f "$FONT_BODY" ]] || {
        echo "Missing body font: $FONT_BODY" >&2
        exit 1
    }
}

seconds_from_timestamp() {
    awk -v value="$1" '
        BEGIN {
            split(value, parts, /[:.]/)
            hours = parts[1] + 0
            minutes = parts[2] + 0
            seconds = parts[3] + 0
            millis = parts[4] + 0
            printf "%.3f", (hours * 3600) + (minutes * 60) + seconds + (millis / 1000)
        }
    '
}

subtitle_entries() {
    local subtitle_file="$1"
    awk '
        BEGIN { RS=""; FS="\n" }
        function to_seconds(value, parts) {
            gsub(",", ".", value)
            split(value, parts, /[:.]/)
            return (parts[1] * 3600) + (parts[2] * 60) + parts[3] + (parts[4] / 1000)
        }
        NF >= 3 {
            split($2, times, " --> ")
            start = to_seconds(times[1]) * factor
            end = to_seconds(times[2]) * factor
            text = ""
            for (i = 3; i <= NF; i++) {
                text = text (i > 3 ? "\\n" : "") $i
            }
            printf "%.3f|%.3f|%s\n", start, end, text
        }
    ' factor="$2" "$subtitle_file"
}

video_duration() {
    "$FFPROBE_BIN" -v error -show_entries format=duration -of csv=p=0 "$1"
}

render_clip() {
    local clip="$1"
    local music_file="${2:-}"
    local input="$RAW_DIR/${clip}.mov"
    local subtitle_file="$SUBTITLE_DIR/${clip}.srt"
    local output="$RENDER_DIR/${clip}.mp4"
    local preview="$PREVIEW_DIR/${clip}.png"
    local tmpdir
    local hook_line_one_file
    local hook_line_two_file
    local cta_file
    local subtitle_root="$SUBTITLE_DIR"
    local subtitle_filters=""
    local raw_duration
    local output_duration
    local fade_out_start
    local audio_input=()
    local audio_map=()
    local audio_filter=""
    local filter_complex
    local subtitle_index=0
    local subtitle_one_path=""
    local subtitle_two_path=""
    local subtitle_line_one=""
    local subtitle_line_two=""
    local stretched_start=""
    local stretched_end=""
    local fallback_still=""
    local use_still_source=0
    local force_still_source=0
    local source_args=()
    local subtitle_factor=""

    clip_config "$clip"

    case "$clip" in
        faq_01_registra_gasto)
            fallback_still="$ROOT/.qa-screens/manual-add-expense-direct2.png"
            ;;
        faq_04_comparte_logro)
            fallback_still="$ROOT/.qa-screens/manual-celebration.png"
            ;;
        faq_05_onboarding_rapido)
            fallback_still="$STILLS_BATCH2_DIR/faq_05_onboarding_rapido.png"
            force_still_source=1
            subtitle_root="$SUBTITLE_BATCH2_DIR"
            ;;
        faq_06_presupuesto_guiado)
            fallback_still="$STILLS_BATCH2_DIR/faq_06_presupuesto_guiado.png"
            force_still_source=1
            subtitle_root="$SUBTITLE_BATCH2_DIR"
            ;;
        faq_07_premium_claro)
            fallback_still="$STILLS_BATCH2_DIR/faq_07_premium_claro.png"
            force_still_source=1
            subtitle_root="$SUBTITLE_BATCH2_DIR"
            ;;
        faq_08_soporte_ayuda)
            fallback_still="$STILLS_BATCH2_DIR/faq_08_soporte_ayuda.png"
            force_still_source=1
            subtitle_root="$SUBTITLE_BATCH2_DIR"
            ;;
        faq_09_inicio_con_control)
            fallback_still="$STILLS_BATCH3_DIR/faq_09_inicio_con_control.png"
            force_still_source=1
            subtitle_root="$SUBTITLE_BATCH3_DIR"
            ;;
        faq_10_cuentas_sin_hojas)
            fallback_still="$STILLS_BATCH3_DIR/faq_10_cuentas_sin_hojas.png"
            force_still_source=1
            subtitle_root="$SUBTITLE_BATCH3_DIR"
            ;;
        faq_11_facturas_sin_sustos)
            fallback_still="$STILLS_BATCH3_DIR/faq_11_facturas_sin_sustos.png"
            force_still_source=1
            subtitle_root="$SUBTITLE_BATCH3_DIR"
            ;;
        faq_12_reglas_que_ayudan)
            fallback_still="$STILLS_BATCH3_DIR/faq_12_reglas_que_ayudan.png"
            force_still_source=1
            subtitle_root="$SUBTITLE_BATCH3_DIR"
            ;;
    esac

    subtitle_file="$subtitle_root/${clip}.srt"

    [[ -f "$subtitle_file" ]] || {
        echo "Missing subtitle file: $subtitle_file" >&2
        exit 1
    }

    if [[ "$force_still_source" -eq 0 ]]; then
        [[ -f "$input" ]] || {
            echo "Missing raw input: $input" >&2
            exit 1
        }
        raw_duration="$(video_duration "$input")"
        output_duration="$(awk -v duration="$raw_duration" -v factor="$SLOW_FACTOR" 'BEGIN { printf "%.3f", duration * factor }')"
        fade_out_start="$(awk -v duration="$output_duration" 'BEGIN { value = duration - 0.45; if (value < 0) value = 0; printf "%.3f", value }')"
    else
        raw_duration="0.000"
        output_duration='6.500'
        fade_out_start='6.050'
    fi

    if [[ -n "$fallback_still" && -f "$fallback_still" ]]; then
        if [[ "$force_still_source" -eq 1 ]] || awk -v duration="$raw_duration" 'BEGIN { exit !(duration < 0.50) }'; then
            use_still_source=1
            output_duration='6.500'
            fade_out_start='6.050'
            source_args=(-loop 1 -t "$output_duration" -i "$fallback_still")
        fi
    fi

    if [[ "$use_still_source" -eq 0 ]]; then
        source_args=(-i "$input")
    fi

    subtitle_factor="$SLOW_FACTOR"
    if [[ "$use_still_source" -eq 1 ]]; then
        subtitle_factor='1.00'
    fi

    tmpdir="$(mktemp -d)"

    hook_line_one_file="$tmpdir/hook_line_one.txt"
    hook_line_two_file="$tmpdir/hook_line_two.txt"
    cta_file="$tmpdir/cta.txt"
    printf '%s' "$HOOK_LINE_ONE" > "$hook_line_one_file"
    printf '%s' "$HOOK_LINE_TWO" > "$hook_line_two_file"
    printf '%s' "$CTA_TEXT" > "$cta_file"

    while IFS='|' read -r start end text; do
        subtitle_one_path="$tmpdir/subtitle_${subtitle_index}_one.txt"
        subtitle_two_path="$tmpdir/subtitle_${subtitle_index}_two.txt"
        subtitle_line_one="${text%%\\n*}"
        subtitle_line_two=""
        stretched_start="$start"
        stretched_end="$end"

        if [[ "$text" == *"\\n"* ]]; then
            subtitle_line_two="${text#*\\n}"
        fi

        printf '%s' "$subtitle_line_one" > "$subtitle_one_path"
        subtitle_filters+="drawtext=fontfile='${FONT_BODY}':textfile='${subtitle_one_path}':reload=1:fontcolor=white:fontsize=42:borderw=2:bordercolor=0x111718:x=(w-text_w)/2:y=1596:enable='between(t,${stretched_start},${stretched_end})',"

        if [[ -n "$subtitle_line_two" ]]; then
            printf '%s' "$subtitle_line_two" > "$subtitle_two_path"
            subtitle_filters+="drawtext=fontfile='${FONT_BODY}':textfile='${subtitle_two_path}':reload=1:fontcolor=white:fontsize=42:borderw=2:bordercolor=0x111718:x=(w-text_w)/2:y=1650:enable='between(t,${stretched_start},${stretched_end})',"
        fi

        subtitle_index=$((subtitle_index + 1))
    done < <(subtitle_entries "$subtitle_file" "$subtitle_factor")

    if [[ -n "$music_file" ]]; then
        [[ -f "$music_file" ]] || {
            echo "Music file not found: $music_file" >&2
            exit 1
        }
        audio_input=(-stream_loop -1 -i "$music_file")
        audio_filter="[1:a]atrim=0:${output_duration},volume=0.10,afade=t=out:st=${fade_out_start}:d=0.45[aout]"
        audio_map=(-map "[aout]")
    else
        audio_input=(-f lavfi -t "$output_duration" -i "anullsrc=channel_layout=stereo:sample_rate=48000")
        audio_filter="[1:a]anull[aout]"
        audio_map=(-map "[aout]")
    fi

    if [[ "$use_still_source" -eq 1 ]]; then
        filter_complex="[0:v]fps=30,split=2[bgsrc][fgsrc];"
    else
        filter_complex="[0:v]setpts=${SLOW_FACTOR}*PTS,fps=30,split=2[bgsrc][fgsrc];"
    fi
    filter_complex+="[bgsrc]scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,gblur=sigma=26,eq=brightness=-0.09:saturation=1.10[bg];"
    filter_complex+="[fgsrc]scale=-1:1500:flags=lanczos[phone];"
    filter_complex+="[bg]drawbox=x=184:y=208:w=712:h=1516:color=black@0.24:t=fill[shadow];"
    filter_complex+="[shadow][phone]overlay=x=(W-w)/2:y=210[base];"
    filter_complex+="[base]drawbox=x=44:y=56:w=992:h=150:color=${SURFACE_COLOR}@0.58:t=fill,"
    filter_complex+="drawbox=x=44:y=56:w=14:h=150:color=${ACCENT_COLOR}@0.95:t=fill,"
    filter_complex+="drawbox=x=70:y=1566:w=940:h=158:color=${SURFACE_COLOR}@0.72:t=fill,"
    filter_complex+="drawbox=x=180:y=1822:w=720:h=64:color=${SURFACE_COLOR}@0.56:t=fill,"
    filter_complex+="drawtext=fontfile='${FONT_DISPLAY}':textfile='${hook_line_one_file}':reload=1:fontcolor=white:fontsize=54:x=90:y=86:alpha='if(lt(t,0.30),t/0.30,1)',"
    filter_complex+="drawtext=fontfile='${FONT_DISPLAY}':textfile='${hook_line_two_file}':reload=1:fontcolor=white:fontsize=54:x=90:y=140:alpha='if(lt(t,0.40),t/0.40,1)',"
    filter_complex+="${subtitle_filters}"
    filter_complex+="drawtext=fontfile='${FONT_BODY}':textfile='${cta_file}':reload=1:fontcolor=${ACCENT_COLOR}:fontsize=30:x=(w-text_w)/2:y=1838[v];"
    filter_complex+="${audio_filter}"

    "$FFMPEG_BIN" -y \
        "${source_args[@]}" \
        "${audio_input[@]}" \
        -filter_complex "$filter_complex" \
        -map "[v]" \
        "${audio_map[@]}" \
        -t "$output_duration" \
        -c:v libx264 \
        -preset medium \
        -crf 18 \
        -pix_fmt yuv420p \
        -movflags +faststart \
        -r 30 \
        -c:a aac \
        -b:a 128k \
        "$output"

    "$FFMPEG_BIN" -y -ss 00:00:01.000 -i "$output" -frames:v 1 "$preview" >/dev/null 2>&1
    rm -rf "$tmpdir"
    echo "Rendered $output"
}

main() {
    local action="${1:-}"
    local target="${2:-}"
    local music_file="${3:-}"

    assert_dependencies

    case "$action" in
        list)
            printf '%s\n' "${ALL_CLIPS[@]}"
            ;;
        render)
            [[ -n "$target" ]] || { usage; exit 1; }
            if [[ "$target" == "all" ]]; then
                local clip
                for clip in "${ALL_CLIPS[@]}"; do
                    render_clip "$clip" "$music_file"
                done
            else
                render_clip "$target" "$music_file"
            fi
            ;;
        *)
            usage
            exit 1
            ;;
    esac
}

main "$@"
