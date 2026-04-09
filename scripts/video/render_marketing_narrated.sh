#!/bin/zsh

set -euo pipefail

ROOT="/Users/rubenlazaro/Projects/spensage-ios"
BASE_VIDEO_DIR="$ROOT/MarketingAssets/tutorial-series/rendered"
VOICE_DIR="$ROOT/MarketingAssets/tutorial-series/voiceovers"
MUSIC_FILE="$ROOT/MarketingAssets/tutorial-series/music/soft_emotional_bed.m4a"
OUTPUT_DIR="$ROOT/MarketingAssets/tutorial-series/rendered-narrated"
PREVIEW_DIR="$ROOT/MarketingAssets/tutorial-series/render-previews-narrated"
FFMPEG_FULL_BIN="/opt/homebrew/opt/ffmpeg-full/bin/ffmpeg"
FFPROBE_FULL_BIN="/opt/homebrew/opt/ffmpeg-full/bin/ffprobe"
FFMPEG_BIN="${FFMPEG_BIN:-$([ -x "$FFMPEG_FULL_BIN" ] && echo "$FFMPEG_FULL_BIN" || command -v ffmpeg)}"
FFPROBE_BIN="${FFPROBE_BIN:-$([ -x "$FFPROBE_FULL_BIN" ] && echo "$FFPROBE_FULL_BIN" || command -v ffprobe)}"

mkdir -p "$OUTPUT_DIR" "$PREVIEW_DIR"

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
  scripts/video/render_marketing_narrated.sh list
  scripts/video/render_marketing_narrated.sh render <clip|all>
EOF
}

video_duration() {
    "$FFPROBE_BIN" -v error -show_entries format=duration -of csv=p=0 "$1"
}

render_clip() {
    local clip="$1"
    local input_video="$BASE_VIDEO_DIR/${clip}.mp4"
    local voice_file="$VOICE_DIR/${clip}.m4a"
    local output_file="$OUTPUT_DIR/${clip}.mp4"
    local preview_file="$PREVIEW_DIR/${clip}.png"
    local duration
    local fade_out_start

    [[ -f "$input_video" ]] || { echo "Missing base video: $input_video" >&2; exit 1; }
    [[ -f "$voice_file" ]] || { echo "Missing voiceover: $voice_file" >&2; exit 1; }
    [[ -f "$MUSIC_FILE" ]] || { echo "Missing background bed: $MUSIC_FILE" >&2; exit 1; }

    duration="$(video_duration "$input_video")"
    fade_out_start="$(awk -v duration="$duration" 'BEGIN { value = duration - 0.75; if (value < 0) value = 0; printf "%.3f", value }')"

    "$FFMPEG_BIN" -y \
        -i "$input_video" \
        -stream_loop -1 -i "$MUSIC_FILE" \
        -i "$voice_file" \
        -filter_complex "\
[1:a]atrim=0:${duration},asetpts=PTS-STARTPTS,volume=0.18,afade=t=in:st=0:d=0.8,afade=t=out:st=${fade_out_start}:d=0.7[bed];\
[2:a]atrim=0:${duration},asetpts=PTS-STARTPTS,adelay=350|350,volume=1.45[voice];\
[bed][voice]sidechaincompress=threshold=0.02:ratio=10:attack=15:release=280[ducked];\
[ducked][voice]amix=inputs=2:weights='1.0 1.0':normalize=0,alimiter=limit=0.95[aout]" \
        -map 0:v \
        -map "[aout]" \
        -c:v copy \
        -c:a aac \
        -b:a 192k \
        -movflags +faststart \
        -shortest \
        "$output_file"

    "$FFMPEG_BIN" -y -ss 00:00:01.000 -i "$output_file" -frames:v 1 "$preview_file" >/dev/null 2>&1
    echo "Rendered $output_file"
}

main() {
    local action="${1:-}"
    local target="${2:-}"

    [[ -n "$FFMPEG_BIN" && -x "$FFMPEG_BIN" ]] || { echo "ffmpeg is required." >&2; exit 1; }
    [[ -n "$FFPROBE_BIN" && -x "$FFPROBE_BIN" ]] || { echo "ffprobe is required." >&2; exit 1; }

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
