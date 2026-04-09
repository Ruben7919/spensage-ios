#!/bin/zsh

set -euo pipefail

ROOT="/Users/rubenlazaro/Projects/spensage-ios"
AUDIO_DIR="$ROOT/MarketingAssets/tutorial-series/audio"
FFMPEG_FULL_BIN="/opt/homebrew/opt/ffmpeg-full/bin/ffmpeg"
FFMPEG_BIN="${FFMPEG_BIN:-$([ -x "$FFMPEG_FULL_BIN" ] && echo "$FFMPEG_FULL_BIN" || command -v ffmpeg)}"
BED_FILE="$AUDIO_DIR/soft_ambient_bed.m4a"
CHIME_FILE="$AUDIO_DIR/soft_brand_chime.m4a"
BED_DURATION="${BED_DURATION:-90}"

usage() {
    cat <<'EOF'
Usage:
  scripts/video/generate_marketing_audio_assets.sh all
  scripts/video/generate_marketing_audio_assets.sh bed
  scripts/video/generate_marketing_audio_assets.sh chime
EOF
}

assert_dependencies() {
    [[ -n "$FFMPEG_BIN" && -x "$FFMPEG_BIN" ]] || { echo "ffmpeg is required." >&2; exit 1; }
    mkdir -p "$AUDIO_DIR"
}

generate_bed() {
    local fade_out_start
    fade_out_start="$(awk -v duration="$BED_DURATION" 'BEGIN { value = duration - 4; if (value < 0) value = 0; printf "%.3f", value }')"

    "$FFMPEG_BIN" -y \
        -f lavfi -t "$BED_DURATION" -i "anoisesrc=color=pink:sample_rate=48000:amplitude=0.5" \
        -f lavfi -t "$BED_DURATION" -i "sine=frequency=196:sample_rate=48000" \
        -f lavfi -t "$BED_DURATION" -i "sine=frequency=293.66:sample_rate=48000" \
        -filter_complex "\
[0:a]lowpass=f=850,highpass=f=90,volume=0.035,afade=t=in:st=0:d=2.2,afade=t=out:st=${fade_out_start}:d=3.8[n];\
[1:a]volume=0.020,lowpass=f=700,afade=t=in:st=0:d=2.0,afade=t=out:st=${fade_out_start}:d=3.8[tone1];\
[2:a]volume=0.014,lowpass=f=900,adelay=1400|1400,afade=t=in:st=0:d=2.0,afade=t=out:st=${fade_out_start}:d=3.8[tone2];\
[n][tone1][tone2]amix=inputs=3:normalize=0,dynaudnorm=f=180:g=7,volume=0.92[a]" \
        -map "[a]" \
        -c:a aac \
        -b:a 192k \
        "$BED_FILE"

    echo "Generated $BED_FILE"
}

generate_chime() {
    "$FFMPEG_BIN" -y \
        -f lavfi -t 1.4 -i "sine=frequency=880:sample_rate=48000" \
        -f lavfi -t 1.4 -i "sine=frequency=1174.66:sample_rate=48000" \
        -f lavfi -t 1.4 -i "sine=frequency=1567.98:sample_rate=48000" \
        -filter_complex "\
[0:a]volume=0.15,afade=t=in:st=0:d=0.01,afade=t=out:st=0.90:d=0.45[a0];\
[1:a]volume=0.10,adelay=50|50,afade=t=in:st=0:d=0.01,afade=t=out:st=0.82:d=0.42[a1];\
[2:a]volume=0.07,adelay=90|90,afade=t=in:st=0:d=0.01,afade=t=out:st=0.72:d=0.36[a2];\
[a0][a1][a2]amix=inputs=3:normalize=0,highpass=f=500,lowpass=f=5000,volume=0.85[a]" \
        -map "[a]" \
        -c:a aac \
        -b:a 160k \
        "$CHIME_FILE"

    echo "Generated $CHIME_FILE"
}

main() {
    local action="${1:-}"

    assert_dependencies

    case "$action" in
        all)
            generate_bed
            generate_chime
            ;;
        bed)
            generate_bed
            ;;
        chime)
            generate_chime
            ;;
        *)
            usage
            exit 1
            ;;
    esac
}

main "$@"
