#!/bin/zsh

set -euo pipefail

ROOT="/Users/rubenlazaro/Projects/spensage-ios"
RAW_DIR="$ROOT/MarketingAssets/tutorial-series/raw"
SUBTITLE_DIR="$ROOT/MarketingAssets/tutorial-series/subtitles"
RENDER_DIR="$ROOT/MarketingAssets/tutorial-series/rendered"
PREVIEW_DIR="$ROOT/MarketingAssets/tutorial-series/render-previews"
FFMPEG_FULL_BIN="/opt/homebrew/opt/ffmpeg-full/bin/ffmpeg"
FFPROBE_FULL_BIN="/opt/homebrew/opt/ffmpeg-full/bin/ffprobe"
FFMPEG_BIN="${FFMPEG_BIN:-$([ -x "$FFMPEG_FULL_BIN" ] && echo "$FFMPEG_FULL_BIN" || command -v ffmpeg)}"
FFPROBE_BIN="${FFPROBE_BIN:-$([ -x "$FFPROBE_FULL_BIN" ] && echo "$FFPROBE_FULL_BIN" || command -v ffprobe)}"
FONT_DISPLAY="${FONT_DISPLAY:-/System/Library/Fonts/SFCompactRounded.ttf}"
FONT_BODY="${FONT_BODY:-/System/Library/Fonts/SFNSRounded.ttf}"
ACCENT_COLOR="0x7FE9E1"
SURFACE_COLOR="0x0D1718"

mkdir -p "$RENDER_DIR" "$PREVIEW_DIR"

typeset -a ALL_CLIPS=(
    tutorial_01_onboarding_first_win
    tutorial_02_home_y_agregar_gasto
    tutorial_03_escaneo_y_guardado
    tutorial_04_analisis_y_presupuesto
    tutorial_05_cuentas_facturas_reglas
    tutorial_06_ajustes_ayuda_y_planes
    tutorial_07_logro_y_share
)

usage() {
    cat <<'EOF'
Usage:
  scripts/video/render_marketing_tutorials.sh render <clip|all> [music_file]
  scripts/video/render_marketing_tutorials.sh list
EOF
}

clip_config() {
    SEGMENT_SPEC=''
    case "$1" in
        tutorial_01_onboarding_first_win)
            HOOK_LINE_ONE='Si te cuesta'
            HOOK_LINE_TWO='empezar, empieza aquí'
            SERIES_TAG='1/7'
            CTA_TEXT='Guárdalo para cuando por fin empieces'
            TRIM_START='8.00'
            ;;
        tutorial_02_home_y_agregar_gasto)
            HOOK_LINE_ONE='Anotar un gasto'
            HOOK_LINE_TWO='debería ser así'
            SERIES_TAG='2/7'
            CTA_TEXT='Si eres de luego lo anoto, guárdalo'
            TRIM_START='12.00'
            ;;
        tutorial_03_escaneo_y_guardado)
            HOOK_LINE_ONE='Así sí da ganas'
            HOOK_LINE_TWO='guardar recibos'
            SERIES_TAG='3/7'
            CTA_TEXT='Mándaselo a quien aún lo pasa a mano'
            TRIM_START='10.00'
            ;;
        tutorial_04_analisis_y_presupuesto)
            HOOK_LINE_ONE='Ver tus gastos así'
            HOOK_LINE_TWO='cambia todo'
            SERIES_TAG='4/7'
            CTA_TEXT='Deja de ajustar a ciegas'
            TRIM_START='10.00'
            ;;
        tutorial_05_cuentas_facturas_reglas)
            HOOK_LINE_ONE='Aquí se acaba'
            HOOK_LINE_TWO='el caos'
            SERIES_TAG='5/7'
            CTA_TEXT='Si ya te cansó el caos, guárdalo'
            TRIM_START='0'
            SEGMENT_SPEC='20.00:7.20,36.00:7.20,50.00:7.40'
            ;;
        tutorial_06_ajustes_ayuda_y_planes)
            HOOK_LINE_ONE='Todo lo importante'
            HOOK_LINE_TWO='está aquí'
            SERIES_TAG='6/7'
            CTA_TEXT='Para resolver algo sin dar vueltas'
            TRIM_START='18.00'
            ;;
        tutorial_07_logro_y_share)
            HOOK_LINE_ONE='Si lo lograste,'
            HOOK_LINE_TWO='compártelo'
            SERIES_TAG='7/7'
            CTA_TEXT='Tu próxima Story merece esto'
            TRIM_START='16.00'
            ;;
        *)
            echo "Unknown clip: $1" >&2
            exit 1
            ;;
    esac
}

assert_dependencies() {
    [[ -n "$FFMPEG_BIN" && -x "$FFMPEG_BIN" ]] || { echo "ffmpeg is required." >&2; exit 1; }
    [[ -n "$FFPROBE_BIN" && -x "$FFPROBE_BIN" ]] || { echo "ffprobe is required." >&2; exit 1; }
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
            start = to_seconds(times[1])
            end = to_seconds(times[2])
            text = ""
            for (i = 3; i <= NF; i++) {
                text = text (i > 3 ? "\\n" : "") $i
            }
            printf "%.3f|%.3f|%s\n", start, end, text
        }
    ' "$subtitle_file"
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
    local raw_duration
    local output_duration
    local fade_out_start
    local tmpdir
    local hook_line_one_file
    local hook_line_two_file
    local series_tag_file
    local cta_file
    local audio_input=()
    local audio_map=()
    local audio_filter=""
    local filter_complex
    local subtitle_filters=""
    local subtitle_index=0
    local subtitle_shift=""
    local video_source_filter=""
    local hook_end_time='2.60'
    local cta_reveal_start

    clip_config "$clip"
    subtitle_shift="$TRIM_START"

    [[ -f "$input" ]] || { echo "Missing raw input: $input" >&2; exit 1; }
    [[ -f "$subtitle_file" ]] || { echo "Missing subtitle file: $subtitle_file" >&2; exit 1; }

    raw_duration="$(video_duration "$input")"
    if [[ -n "$SEGMENT_SPEC" ]]; then
        output_duration="$(awk -v spec="$SEGMENT_SPEC" 'BEGIN { split(spec, items, ","); sum = 0; for (i in items) { split(items[i], pair, ":"); sum += pair[2]; } printf "%.3f", sum }')"
        subtitle_shift='0'
    else
        output_duration="$(awk -v duration="$raw_duration" -v trim="$TRIM_START" 'BEGIN { value = duration - trim; if (value < 4.0) value = duration; printf "%.3f", value }')"
    fi
    fade_out_start="$(awk -v duration="$output_duration" 'BEGIN { value = duration - 0.45; if (value < 0) value = 0; printf "%.3f", value }')"
    cta_reveal_start="$(awk -v duration="$output_duration" 'BEGIN { value = duration - 1.60; if (value < 0) value = 0; printf "%.3f", value }')"

    tmpdir="$(mktemp -d)"
    hook_line_one_file="$tmpdir/hook_line_one.txt"
    hook_line_two_file="$tmpdir/hook_line_two.txt"
    series_tag_file="$tmpdir/series_tag.txt"
    cta_file="$tmpdir/cta.txt"

    printf '%s' "$HOOK_LINE_ONE" > "$hook_line_one_file"
    printf '%s' "$HOOK_LINE_TWO" > "$hook_line_two_file"
    printf '%s' "$SERIES_TAG" > "$series_tag_file"
    printf '%s' "$CTA_TEXT" > "$cta_file"

    while IFS='|' read -r start end text; do
        local subtitle_one_path="$tmpdir/subtitle_${subtitle_index}_one.txt"
        local subtitle_two_path="$tmpdir/subtitle_${subtitle_index}_two.txt"
        local subtitle_line_one="${text%%\\n*}"
        local subtitle_line_two=""
        local subtitle_box_y='1462'
        local subtitle_box_h='118'
        local subtitle_line_one_y='1498'
        local subtitle_line_two_y='0'
        local adjusted_start
        local adjusted_end

        adjusted_start="$(awk -v value="$start" -v shift="$subtitle_shift" 'BEGIN { out = value - shift; if (out < 0) out = 0; printf "%.3f", out }')"
        adjusted_end="$(awk -v value="$end" -v shift="$subtitle_shift" 'BEGIN { out = value - shift; if (out < 0) out = 0; printf "%.3f", out }')"

        if [[ "$text" == *"\\n"* ]]; then
            subtitle_line_two="${text#*\\n}"
            subtitle_line_one_y='1482'
            subtitle_line_two_y='1532'
        fi

        printf '%s' "$subtitle_line_one" > "$subtitle_one_path"
        subtitle_filters+="drawbox=x=118:y=${subtitle_box_y}:w=844:h=${subtitle_box_h}:color=${SURFACE_COLOR}@0.60:t=fill:enable='between(t,${adjusted_start},${adjusted_end})',"
        subtitle_filters+="drawbox=x=118:y=${subtitle_box_y}:w=844:h=${subtitle_box_h}:color=white@0.08:t=2:enable='between(t,${adjusted_start},${adjusted_end})',"
        subtitle_filters+="drawtext=fontfile='${FONT_BODY}':textfile='${subtitle_one_path}':reload=1:fontcolor=white:fontsize=48:shadowcolor=0x071214@0.55:shadowx=0:shadowy=5:x=(w-text_w)/2:y=${subtitle_line_one_y}:enable='between(t,${adjusted_start},${adjusted_end})',"

        if [[ -n "$subtitle_line_two" ]]; then
            printf '%s' "$subtitle_line_two" > "$subtitle_two_path"
            subtitle_filters+="drawtext=fontfile='${FONT_BODY}':textfile='${subtitle_two_path}':reload=1:fontcolor=white:fontsize=48:shadowcolor=0x071214@0.55:shadowx=0:shadowy=5:x=(w-text_w)/2:y=${subtitle_line_two_y}:enable='between(t,${adjusted_start},${adjusted_end})',"
        fi

        subtitle_index=$((subtitle_index + 1))
    done < <(subtitle_entries "$subtitle_file")

    if [[ -n "$music_file" ]]; then
        [[ -f "$music_file" ]] || { echo "Music file not found: $music_file" >&2; exit 1; }
        audio_input=(-stream_loop -1 -i "$music_file")
        audio_filter="[1:a]atrim=0:${output_duration},volume=0.12,afade=t=out:st=${fade_out_start}:d=0.45[aout]"
    else
        audio_input=(-f lavfi -t "$output_duration" -i "anullsrc=channel_layout=stereo:sample_rate=48000")
        audio_filter="[1:a]anull[aout]"
    fi
    audio_map=(-map "[aout]")

    if [[ -n "$SEGMENT_SPEC" ]]; then
        local segment_index=0
        local concat_inputs=""
        local segment_pairs=("${(@s:,:)SEGMENT_SPEC}")
        local pair
        for pair in "${segment_pairs[@]}"; do
            local segment_start="${pair%%:*}"
            local segment_duration="${pair##*:}"
            video_source_filter+="[0:v]trim=start=${segment_start}:duration=${segment_duration},setpts=PTS-STARTPTS,fps=30[seg${segment_index}];"
            concat_inputs+="[seg${segment_index}]"
            segment_index=$((segment_index + 1))
        done
        video_source_filter+="${concat_inputs}concat=n=${segment_index}:v=1:a=0[trimmed];"
        filter_complex="${video_source_filter}[trimmed]split=2[bgsrc][fgsrc];"
    else
        filter_complex="[0:v]trim=start=${TRIM_START},setpts=PTS-STARTPTS,fps=30,split=2[bgsrc][fgsrc];"
    fi
    filter_complex+="[bgsrc]scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,gblur=sigma=26,eq=brightness=-0.09:saturation=1.10[bg];"
    filter_complex+="[fgsrc]scale=-1:1500:flags=lanczos[phone];"
    filter_complex+="[bg]drawbox=x=184:y=208:w=712:h=1516:color=black@0.24:t=fill[shadow];"
    filter_complex+="[shadow][phone]overlay=x=(W-w)/2:y=210[base];"
    filter_complex+="[base]drawbox=x=30:y=42:w=580:h=142:color=${SURFACE_COLOR}@0.46:t=fill:enable='between(t,0,${hook_end_time})',"
    filter_complex+="drawbox=x=30:y=42:w=580:h=142:color=white@0.08:t=2:enable='between(t,0,${hook_end_time})',"
    filter_complex+="drawbox=x=26:y=56:w=6:h=96:color=${ACCENT_COLOR}@0.96:t=fill:enable='between(t,0,${hook_end_time})',"
    filter_complex+="drawbox=x=860:y=54:w=150:h=48:color=${ACCENT_COLOR}@0.14:t=fill:enable='between(t,0,${hook_end_time})',"
    filter_complex+="drawbox=x=860:y=54:w=150:h=48:color=${ACCENT_COLOR}@0.45:t=2:enable='between(t,0,${hook_end_time})',"
    filter_complex+="drawtext=fontfile='${FONT_BODY}':textfile='${series_tag_file}':reload=1:fontcolor=${ACCENT_COLOR}:fontsize=24:shadowcolor=0x071214@0.40:shadowx=0:shadowy=4:x=(860+(150-text_w)/2):y=66:enable='between(t,0,${hook_end_time})',"
    filter_complex+="drawtext=fontfile='${FONT_DISPLAY}':textfile='${hook_line_one_file}':reload=1:fontcolor=white:fontsize=56:shadowcolor=0x071214@0.48:shadowx=0:shadowy=5:x=46:y=56:enable='between(t,0,${hook_end_time})',"
    filter_complex+="drawtext=fontfile='${FONT_DISPLAY}':textfile='${hook_line_two_file}':reload=1:fontcolor=white:fontsize=56:shadowcolor=0x071214@0.48:shadowx=0:shadowy=5:x=46:y=112:enable='between(t,0,${hook_end_time})',"
    filter_complex+="${subtitle_filters}"
    filter_complex+="drawbox=x=156:y=1826:w=768:h=68:color=${SURFACE_COLOR}@0.46:t=fill:enable='between(t,${cta_reveal_start},${output_duration})',"
    filter_complex+="drawbox=x=156:y=1826:w=768:h=68:color=white@0.08:t=2:enable='between(t,${cta_reveal_start},${output_duration})',"
    filter_complex+="drawtext=fontfile='${FONT_BODY}':textfile='${cta_file}':reload=1:fontcolor=${ACCENT_COLOR}:fontsize=30:shadowcolor=0x071214@0.45:shadowx=0:shadowy=4:x=(w-text_w)/2:y=1846:enable='between(t,${cta_reveal_start},${output_duration})'[v];"
    filter_complex+="${audio_filter}"

    "$FFMPEG_BIN" -y \
        -i "$input" \
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
