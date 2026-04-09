#!/bin/zsh

set -euo pipefail

ROOT="/Users/rubenlazaro/Projects/spensage-ios"
APP_ID="com.spendsage.ai"
RAW_DIR="$ROOT/MarketingAssets/faq-videos/raw"
EXPORTED_DIR="$ROOT/MarketingAssets/faq-videos/exported"
PREFERRED_DEVICE_NAME="${PREFERRED_DEVICE_NAME:-iPhone 16 Pro}"
PREFERRED_RUNTIME="${PREFERRED_RUNTIME:-18.6}"

mkdir -p "$RAW_DIR" "$EXPORTED_DIR"

usage() {
    cat <<'EOF'
Usage:
  scripts/video/record_faq_clips.sh record <clip|all>
  scripts/video/record_faq_clips.sh export <clip|all>
  scripts/video/record_faq_clips.sh list

Clips:
  faq_01_registra_gasto
  faq_02_escanea_recibo
  faq_03_lee_analisis
  faq_04_comparte_logro
EOF
}

all_clips=(
    faq_01_registra_gasto
    faq_02_escanea_recibo
    faq_03_lee_analisis
    faq_04_comparte_logro
)

resolve_udid() {
    local booted
    booted=$(xcrun simctl list devices | awk -F '[()]' '/Booted/ && /iPhone/ {print $2; exit}')
    if [[ -n "$booted" ]]; then
        echo "$booted"
        return
    fi

    xcrun simctl list devices available | awk -v name="$PREFERRED_DEVICE_NAME" -v runtime="$PREFERRED_RUNTIME" '
        $0 ~ "-- iOS " runtime " --" { in_runtime=1; next }
        /^--/ { in_runtime=0 }
        in_runtime && $0 ~ name { print; exit }
    ' | sed -E 's/.*\(([A-F0-9-]+)\).*/\1/'
}

ensure_booted() {
    local udid="$1"
    open -a Simulator >/dev/null 2>&1 || true
    xcrun simctl boot "$udid" >/dev/null 2>&1 || true
    xcrun simctl bootstatus "$udid" -b
}

latest_app_bundle() {
    find "$HOME/Library/Developer/Xcode/DerivedData" \
        -path '*Build/Products/Debug-iphonesimulator/SpendSage.app' \
        -type d \
        | sort \
        | tail -1
}

install_latest_build_if_present() {
    local udid="$1"
    local bundle
    bundle="$(latest_app_bundle || true)"
    if [[ -n "$bundle" && -d "$bundle" ]]; then
        xcrun simctl install "$udid" "$bundle" >/dev/null
    fi
}

apply_clean_status_bar() {
    local udid="$1"
    xcrun simctl status_bar "$udid" override \
        --time 9:41 \
        --dataNetwork wifi \
        --wifiBars 3 \
        --cellularMode active \
        --cellularBars 4 \
        --batteryState charged \
        --batteryLevel 100 >/dev/null
}

launch_with_env() {
    local udid="$1"
    shift
    xcrun simctl terminate "$udid" "$APP_ID" >/dev/null 2>&1 || true
    env "$@" xcrun simctl launch --terminate-running-process "$udid" "$APP_ID" >/dev/null
}

record_duration() {
    local udid="$1"
    local output="$2"
    local duration="$3"

    rm -f "$output"
    (
        xcrun simctl io "$udid" recordVideo --codec=h264 --force "$output" \
            >/tmp/spendsage-video.out 2>/tmp/spendsage-video.err
    ) &
    local rec_pid=$!
    sleep "$duration"
    kill -INT "$rec_pid"
    wait "$rec_pid" || true
}

record_clip() {
    local clip="$1"
    local udid="$2"
    local duration
    local settle_delay=1
    local output="$RAW_DIR/${clip}.mov"

    case "$clip" in
        faq_01_registra_gasto)
            duration=8
            settle_delay=2
            launch_with_env "$udid" \
                SIMCTL_CHILD_SPENDSAGE_DEBUG_SCREEN=shell \
                SIMCTL_CHILD_SPENDSAGE_DEBUG_TAB=expenses \
                SIMCTL_CHILD_SPENDSAGE_DEBUG_SKIP_SPLASH=1 \
                SIMCTL_CHILD_SPENDSAGE_DEBUG_HIDE_GUIDES=1 \
                SIMCTL_CHILD_SPENDSAGE_DEBUG_MODAL=add_expense
            ;;
        faq_02_escanea_recibo)
            duration=9
            launch_with_env "$udid" \
                SIMCTL_CHILD_SPENDSAGE_DEBUG_ROUTE=scan \
                SIMCTL_CHILD_SPENDSAGE_DEBUG_SKIP_SPLASH=1 \
                SIMCTL_CHILD_SPENDSAGE_DEBUG_HIDE_GUIDES=1 \
                SIMCTL_CHILD_SPENDSAGE_DEBUG_SCAN_STATE=review
            ;;
        faq_03_lee_analisis)
            duration=9
            launch_with_env "$udid" \
                SIMCTL_CHILD_SPENDSAGE_DEBUG_SCREEN=shell \
                SIMCTL_CHILD_SPENDSAGE_DEBUG_TAB=insights \
                SIMCTL_CHILD_SPENDSAGE_DEBUG_SKIP_SPLASH=1 \
                SIMCTL_CHILD_SPENDSAGE_DEBUG_HIDE_GUIDES=1 \
                SIMCTL_CHILD_SPENDSAGE_DEBUG_INSIGHTS_SELECTION=3
            ;;
        faq_04_comparte_logro)
            duration=8
            settle_delay=2
            launch_with_env "$udid" \
                SIMCTL_CHILD_SPENDSAGE_DEBUG_SCREEN=shell \
                SIMCTL_CHILD_SPENDSAGE_DEBUG_TAB=dashboard \
                SIMCTL_CHILD_SPENDSAGE_DEBUG_SKIP_SPLASH=1 \
                SIMCTL_CHILD_SPENDSAGE_DEBUG_HIDE_GUIDES=1 \
                SIMCTL_CHILD_SPENDSAGE_DEBUG_CELEBRATION=trophy
            ;;
        *)
            echo "Unknown clip: $clip" >&2
            exit 1
            ;;
    esac

    sleep "$settle_delay"
    record_duration "$udid" "$output" "$duration"
    echo "Recorded $output"
}

export_clip() {
    local clip="$1"
    local input="$RAW_DIR/${clip}.mov"
    local output="$EXPORTED_DIR/${clip}.m4v"

    if [[ ! -f "$input" ]]; then
        echo "Missing raw clip: $input" >&2
        exit 1
    fi

    avconvert \
        --source "$input" \
        --output "$output" \
        --preset PresetHEVCHighestQuality \
        --replace >/dev/null

    echo "Exported $output"
}

main() {
    local action="${1:-}"
    local target="${2:-}"

    case "$action" in
        list)
            printf '%s\n' "${all_clips[@]}"
            ;;
        record)
            [[ -n "$target" ]] || { usage; exit 1; }
            local udid
            udid="$(resolve_udid)"
            [[ -n "$udid" ]] || { echo "No iPhone simulator available." >&2; exit 1; }
            ensure_booted "$udid"
            install_latest_build_if_present "$udid"
            apply_clean_status_bar "$udid"
            if [[ "$target" == "all" ]]; then
                local clip
                for clip in "${all_clips[@]}"; do
                    record_clip "$clip" "$udid"
                done
            else
                record_clip "$target" "$udid"
            fi
            ;;
        export)
            [[ -n "$target" ]] || { usage; exit 1; }
            if [[ "$target" == "all" ]]; then
                local clip
                for clip in "${all_clips[@]}"; do
                    export_clip "$clip"
                done
            else
                export_clip "$target"
            fi
            ;;
        *)
            usage
            exit 1
            ;;
    esac
}

main "$@"
