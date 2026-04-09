#!/bin/zsh

set -euo pipefail

ROOT="/Users/rubenlazaro/Projects/spensage-ios"
MUSIC_DIR="$ROOT/MarketingAssets/tutorial-series/music"
OUTPUT="$MUSIC_DIR/soft_emotional_bed.m4a"
FFMPEG_FULL_BIN="/opt/homebrew/opt/ffmpeg-full/bin/ffmpeg"
FFMPEG_BIN="${FFMPEG_BIN:-$([ -x "$FFMPEG_FULL_BIN" ] && echo "$FFMPEG_FULL_BIN" || command -v ffmpeg)}"
DURATION="${DURATION:-90}"

mkdir -p "$MUSIC_DIR"

[[ -n "$FFMPEG_BIN" && -x "$FFMPEG_BIN" ]] || {
    echo "ffmpeg is required." >&2
    exit 1
}

"$FFMPEG_BIN" -y \
    -f lavfi -i "sine=frequency=220:sample_rate=48000:duration=${DURATION}" \
    -f lavfi -i "sine=frequency=277.18:sample_rate=48000:duration=${DURATION}" \
    -f lavfi -i "sine=frequency=329.63:sample_rate=48000:duration=${DURATION}" \
    -f lavfi -i "anoisesrc=color=pink:sample_rate=48000:duration=${DURATION}" \
    -filter_complex "\
[0:a]volume='0.045*(0.78+0.22*sin(2*PI*0.10*t))',lowpass=f=340[a0];\
[1:a]volume='0.028*(0.76+0.24*sin(2*PI*0.12*t+0.8))',lowpass=f=620[a1];\
[2:a]volume='0.020*(0.74+0.26*sin(2*PI*0.14*t+1.2))',lowpass=f=980[a2];\
[3:a]volume='0.0025*(0.80+0.20*sin(2*PI*0.08*t))',highpass=f=180,lowpass=f=2400[noise];\
[a0][a1][a2][noise]amix=inputs=4:normalize=0,\
aformat=channel_layouts=stereo,\
afade=t=in:st=0:d=1.5,\
afade=t=out:st=$(awk -v d="$DURATION" 'BEGIN { printf "%.2f", d - 2.5 }'):d=2.5,\
alimiter=limit=0.85[aout]" \
    -map "[aout]" \
    -c:a aac \
    -b:a 192k \
    "$OUTPUT"

echo "Generated $OUTPUT"
