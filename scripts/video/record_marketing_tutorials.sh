#!/bin/zsh

set -euo pipefail

ROOT="/Users/rubenlazaro/Projects/spensage-ios"
PROJECT="$ROOT/SpendSage.xcodeproj"
SCHEME="SpendSage"
RAW_DIR="$ROOT/MarketingAssets/tutorial-series/raw"
LOG_DIR="$ROOT/MarketingAssets/tutorial-series/logs"
PREFERRED_DEVICE_NAME="${PREFERRED_DEVICE_NAME:-iPhone 16 Pro}"
PREFERRED_RUNTIME="${PREFERRED_RUNTIME:-18.6}"

mkdir -p "$RAW_DIR" "$LOG_DIR"

usage() {
    cat <<'EOF'
Usage:
  scripts/video/record_marketing_tutorials.sh list
  scripts/video/record_marketing_tutorials.sh record <clip|all>

Clips:
  tutorial_01_onboarding_first_win
  tutorial_02_home_y_agregar_gasto
  tutorial_03_escaneo_y_guardado
  tutorial_04_analisis_y_presupuesto
  tutorial_05_cuentas_facturas_reglas
  tutorial_06_ajustes_ayuda_y_planes
  tutorial_07_logro_y_share
EOF
}

all_clips=(
    tutorial_01_onboarding_first_win
    tutorial_02_home_y_agregar_gasto
    tutorial_03_escaneo_y_guardado
    tutorial_04_analisis_y_presupuesto
    tutorial_05_cuentas_facturas_reglas
    tutorial_06_ajustes_ayuda_y_planes
    tutorial_07_logro_y_share
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

prepare_for_testing() {
    local udid="$1"
    local build_log="$LOG_DIR/build-for-testing.log"

    xcodebuild build-for-testing \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination "platform=iOS Simulator,id=$udid" \
        -parallel-testing-enabled NO \
        ONLY_ACTIVE_ARCH=YES ARCHS=arm64 \
        >"$build_log" 2>&1
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

test_name_for_clip() {
    case "$1" in
        tutorial_01_onboarding_first_win)
            echo "SpendSageUITests/SpendSageTutorialUITests/testTutorial01OnboardingFirstWin"
            ;;
        tutorial_02_home_y_agregar_gasto)
            echo "SpendSageUITests/SpendSageTutorialUITests/testTutorial02DashboardAndAddExpense"
            ;;
        tutorial_03_escaneo_y_guardado)
            echo "SpendSageUITests/SpendSageTutorialUITests/testTutorial03ScanReceiptReviewAndSave"
            ;;
        tutorial_04_analisis_y_presupuesto)
            echo "SpendSageUITests/SpendSageTutorialUITests/testTutorial04InsightsAndBudgetWizard"
            ;;
        tutorial_05_cuentas_facturas_reglas)
            echo "SpendSageUITests/SpendSageTutorialUITests/testTutorial05AccountsBillsAndRules"
            ;;
        tutorial_06_ajustes_ayuda_y_planes)
            echo "SpendSageUITests/SpendSageTutorialUITests/testTutorial06SettingsHelpSupportAndPlans"
            ;;
        tutorial_07_logro_y_share)
            echo "SpendSageUITests/SpendSageTutorialUITests/testTutorial07CelebrationShare"
            ;;
        *)
            echo "Unknown clip: $1" >&2
            exit 1
            ;;
    esac
}

record_clip() {
    local clip="$1"
    local udid="$2"
    local output="$RAW_DIR/${clip}.mov"
    local log_file="$LOG_DIR/${clip}.log"
    local test_name
    local rec_pid

    test_name="$(test_name_for_clip "$clip")"

    rm -f "$output" "$log_file"
    pkill -INT -f "simctl io .* recordVideo" >/dev/null 2>&1 || true
    sleep 1

    (
        xcrun simctl io "$udid" recordVideo --codec=h264 --force "$output" \
            >/tmp/spendsage-tutorial-video.out 2>/tmp/spendsage-tutorial-video.err
    ) &
    rec_pid=$!

    set +e
    xcodebuild test-without-building \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination "platform=iOS Simulator,id=$udid" \
        -parallel-testing-enabled NO \
        -only-testing:"$test_name" \
        ONLY_ACTIVE_ARCH=YES ARCHS=arm64 \
        >"$log_file" 2>&1
    local test_exit_code=$?
    set -e

    sleep 1
    kill -INT "$rec_pid" >/dev/null 2>&1 || true
    wait "$rec_pid" >/dev/null 2>&1 || true

    if [[ "$test_exit_code" -ne 0 ]]; then
        echo "Tutorial test failed for $clip. See $log_file" >&2
        exit "$test_exit_code"
    fi

    [[ -f "$output" ]] || {
        echo "Recording did not produce an output file for $clip." >&2
        cat /tmp/spendsage-tutorial-video.err >&2 || true
        exit 1
    }

    echo "Recorded $output"
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
            apply_clean_status_bar "$udid"
            prepare_for_testing "$udid"
            if [[ "$target" == "all" ]]; then
                local clip
                for clip in "${all_clips[@]}"; do
                    record_clip "$clip" "$udid"
                done
            else
                record_clip "$target" "$udid"
            fi
            ;;
        *)
            usage
            exit 1
            ;;
    esac
}

main "$@"
