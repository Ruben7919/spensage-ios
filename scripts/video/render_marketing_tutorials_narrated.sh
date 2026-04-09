#!/bin/zsh

set -euo pipefail

ROOT="/Users/rubenlazaro/Projects/spensage-ios"
INPUT_DIR="$ROOT/MarketingAssets/tutorial-series/rendered"
VOICEOVER_DIR="$ROOT/MarketingAssets/tutorial-series/voiceovers"
AUDIO_DIR="$ROOT/MarketingAssets/tutorial-series/audio"
OUTPUT_DIR="$ROOT/MarketingAssets/tutorial-series/rendered-narrated"
PREVIEW_DIR="$ROOT/MarketingAssets/tutorial-series/render-previews-narrated"
FFMPEG_FULL_BIN="/opt/homebrew/opt/ffmpeg-full/bin/ffmpeg"
FFPROBE_FULL_BIN="/opt/homebrew/opt/ffmpeg-full/bin/ffprobe"
FFMPEG_BIN="${FFMPEG_BIN:-$([ -x "$FFMPEG_FULL_BIN" ] && echo "$FFMPEG_FULL_BIN" || command -v ffmpeg)}"
FFPROBE_BIN="${FFPROBE_BIN:-$([ -x "$FFPROBE_FULL_BIN" ] && echo "$FFPROBE_FULL_BIN" || command -v ffprobe)}"
BED_FILE="$AUDIO_DIR/soft_ambient_bed.m4a"
CHIME_FILE="$AUDIO_DIR/soft_brand_chime.m4a"
VOICE_DELAY_MS="${VOICE_DELAY_MS:-220}"

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
  scripts/video/render_marketing_tutorials_narrated.sh render <clip|all>
  scripts/video/render_marketing_tutorials_narrated.sh list
EOF
}

assert_dependencies() {
    [[ -n "$FFMPEG_BIN" && -x "$FFMPEG_BIN" ]] || { echo "ffmpeg is required." >&2; exit 1; }
    [[ -n "$FFPROBE_BIN" && -x "$FFPROBE_BIN" ]] || { echo "ffprobe is required." >&2; exit 1; }
    [[ -f "$BED_FILE" ]] || { echo "Missing background bed: $BED_FILE" >&2; exit 1; }
    [[ -f "$CHIME_FILE" ]] || { echo "Missing brand chime: $CHIME_FILE" >&2; exit 1; }
    mkdir -p "$OUTPUT_DIR" "$PREVIEW_DIR"
}

media_duration() {
    "$FFPROBE_BIN" -v error -show_entries format=duration -of csv=p=0 "$1"
}

render_clip() {
    local clip="$1"
    local input="$INPUT_DIR/${clip}.mp4"
    local voice="$VOICEOVER_DIR/${clip}.m4a"
    local output="$OUTPUT_DIR/${clip}.mp4"
    local preview="$PREVIEW_DIR/${clip}.png"
    local duration
    local voice_duration
    local fade_out_start
    local available_voice_window
    local tempo
    local target_duration
    local end_chime_ms

    [[ -f "$input" ]] || { echo "Missing rendered input: $input" >&2; exit 1; }
    [[ -f "$voice" ]] || { echo "Missing voiceover audio: $voice" >&2; exit 1; }

    duration="$(media_duration "$input")"
    voice_duration="$(media_duration "$voice")"
    target_duration="$(awk -v total="$duration" -v voice="$voice_duration" -v delay="$VOICE_DELAY_MS" 'BEGIN { value = (delay / 1000.0) + voice + 1.0; if (value > total) value = total; if (value < 4.0) value = total; printf "%.3f", value }')"
    fade_out_start="$(awk -v total="$target_duration" 'BEGIN { value = total - 0.65; if (value < 0) value = 0; printf "%.3f", value }')"
    available_voice_window="$(awk -v total="$duration" -v delay="$VOICE_DELAY_MS" 'BEGIN { value = total - (delay / 1000.0) - 0.45; if (value < 1.0) value = 1.0; printf "%.3f", value }')"
    tempo="$(awk -v voice="$voice_duration" -v available="$available_voice_window" 'BEGIN { value = voice / available; if (value < 1.0) value = 1.0; if (value > 1.22) value = 1.22; printf "%.3f", value }')"
    end_chime_ms="$(awk -v total="$target_duration" 'BEGIN { value = int((total - 0.90) * 1000); if (value < 400) value = 400; printf "%d", value }')"

    "$FFMPEG_BIN" -y \
        -i "$input" \
        -stream_loop -1 -i "$BED_FILE" \
        -i "$voice" \
        -i "$CHIME_FILE" \
        -filter_complex "\
[1:a]atrim=0:${target_duration},volume=0.075,afade=t=in:st=0:d=0.8,afade=t=out:st=${fade_out_start}:d=0.65[music];\
[2:a]aformat=sample_fmts=fltp:sample_rates=48000:channel_layouts=stereo,highpass=f=90,atempo=${tempo},adelay=${VOICE_DELAY_MS}|${VOICE_DELAY_MS},volume=1.16,acompressor=threshold=0.10:ratio=2.4:attack=12:release=180[voice];\
[3:a]atrim=0:0.35,adelay=120|120,volume=0.11[chime_start];\
[3:a]atrim=0:0.30,adelay=${end_chime_ms}|${end_chime_ms},volume=0.08[chime_end];\
[music][voice]sidechaincompress=threshold=0.020:ratio=7:attack=20:release=300[ducked];\
[ducked][voice][chime_start][chime_end]amix=inputs=4:normalize=0:weights='1 1 0.55 0.40',loudnorm=I=-16:LRA=10:TP=-1.5[a]" \
        -map 0:v \
        -map "[a]" \
        -t "$target_duration" \
        -c:v copy \
        -c:a aac \
        -b:a 192k \
        -movflags +faststart \
        "$output"

    "$FFMPEG_BIN" -y -ss 00:00:01.000 -i "$output" -frames:v 1 "$preview" >/dev/null 2>&1
    echo "Rendered $output"
}

main() {
    local action="${1:-}"
    local target="${2:-}"

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
                    render_clip "$clip"
                done
            else
                render_clip "$target"
            fi
            ;;
        *)
            usage
            exit 1
            ;;
    esac
}

main "$@"
