#!/bin/zsh

set -euo pipefail

ROOT="/Users/rubenlazaro/Projects/spensage-ios"
SCRIPT_DIR="$ROOT/MarketingAssets/launch-campaign/voiceover-scripts"
VOICEOVER_DIR="$ROOT/MarketingAssets/launch-campaign/voiceovers"
TMP_DIR="$VOICEOVER_DIR/raw-aiff"
FFMPEG_FULL_BIN="/opt/homebrew/opt/ffmpeg-full/bin/ffmpeg"
FFMPEG_BIN="${FFMPEG_BIN:-$([ -x "$FFMPEG_FULL_BIN" ] && echo "$FFMPEG_FULL_BIN" || command -v ffmpeg)}"
AFCONVERT_BIN="${AFCONVERT_BIN:-$(command -v afconvert)}"
VOICE_NAME="${VOICE_NAME:-Paulina}"
VOICE_RATE="${VOICE_RATE:-186}"

typeset -a ALL_CLIPS=(
    launch_01_main_story
    launch_02_teaser_short
)

usage() {
    cat <<'EOF'
Usage:
  scripts/video/synthesize_launch_voiceovers.sh synth <clip|all> [voice_name]
  scripts/video/synthesize_launch_voiceovers.sh list-voices
EOF
}

assert_dependencies() {
    command -v say >/dev/null 2>&1 || { echo "say is required." >&2; exit 1; }
    [[ -n "$AFCONVERT_BIN" && -x "$AFCONVERT_BIN" ]] || { echo "afconvert is required." >&2; exit 1; }
    mkdir -p "$VOICEOVER_DIR" "$TMP_DIR"
}

synthesize_clip() {
    local clip="$1"
    local voice_name="${2:-$VOICE_NAME}"
    local input="$SCRIPT_DIR/${clip}.txt"
    local tmp_aiff="$TMP_DIR/${clip}.aiff"
    local output="$VOICEOVER_DIR/${clip}.m4a"

    [[ -f "$input" ]] || { echo "Missing voiceover script: $input" >&2; exit 1; }

    say -v "$voice_name" -r "$VOICE_RATE" -f "$input" -o "$tmp_aiff"

    rm -f "$output"
    "$AFCONVERT_BIN" "$tmp_aiff" -o "$output" -f m4af -d aac

    echo "Generated $output"
}

main() {
    local action="${1:-}"
    local target="${2:-}"
    local voice_name="${3:-$VOICE_NAME}"

    assert_dependencies

    case "$action" in
        list-voices)
            say -v '?'
            ;;
        synth)
            [[ -n "$target" ]] || { usage; exit 1; }
            if [[ "$target" == "all" ]]; then
                local clip
                for clip in "${ALL_CLIPS[@]}"; do
                    synthesize_clip "$clip" "$voice_name"
                done
            else
                synthesize_clip "$target" "$voice_name"
            fi
            ;;
        *)
            usage
            exit 1
            ;;
    esac
}

main "$@"
