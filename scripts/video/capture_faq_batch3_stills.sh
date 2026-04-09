#!/bin/zsh

set -euo pipefail

ROOT="/Users/rubenlazaro/Projects/spensage-ios"
OUT_DIR="$ROOT/MarketingAssets/faq-videos/stills-batch3"
UDID="${UDID:-5C6156AE-37BA-45CD-81AE-0A16A530E5A8}"
APP_ID="com.spendsage.ai"

mkdir -p "$OUT_DIR"

launch() {
    xcrun simctl terminate "$UDID" "$APP_ID" >/dev/null 2>&1 || true
    env "$@" xcrun simctl launch --terminate-running-process "$UDID" "$APP_ID" >/dev/null
    sleep "${SETTLE_DELAY:-2.5}"
}

capture() {
    local name="$1"
    shift
    SETTLE_DELAY="${SETTLE_DELAY:-2.5}" launch "$@"
    xcrun simctl io "$UDID" screenshot "$OUT_DIR/${name}.png" >/dev/null
    echo "Captured $OUT_DIR/${name}.png"
}

xcrun simctl status_bar "$UDID" override \
    --time 9:41 \
    --dataNetwork wifi \
    --wifiBars 3 \
    --cellularMode active \
    --cellularBars 4 \
    --batteryState charged \
    --batteryLevel 100 >/dev/null

SETTLE_DELAY=5 capture faq_09_inicio_con_control \
    SIMCTL_CHILD_SPENDSAGE_DEBUG_ROUTE=dashboard \
    SIMCTL_CHILD_SPENDSAGE_DEBUG_HIDE_GUIDES=1 \
    SIMCTL_CHILD_SPENDSAGE_DEBUG_SKIP_SPLASH=1

SETTLE_DELAY=2.5 capture faq_10_cuentas_sin_hojas \
    SIMCTL_CHILD_SPENDSAGE_DEBUG_ROUTE=accounts \
    SIMCTL_CHILD_SPENDSAGE_DEBUG_HIDE_GUIDES=1 \
    SIMCTL_CHILD_SPENDSAGE_DEBUG_SKIP_SPLASH=1

SETTLE_DELAY=2.5 capture faq_11_facturas_sin_sustos \
    SIMCTL_CHILD_SPENDSAGE_DEBUG_ROUTE=bills \
    SIMCTL_CHILD_SPENDSAGE_DEBUG_HIDE_GUIDES=1 \
    SIMCTL_CHILD_SPENDSAGE_DEBUG_SKIP_SPLASH=1

SETTLE_DELAY=2.5 capture faq_12_reglas_que_ayudan \
    SIMCTL_CHILD_SPENDSAGE_DEBUG_ROUTE=rules \
    SIMCTL_CHILD_SPENDSAGE_DEBUG_HIDE_GUIDES=1 \
    SIMCTL_CHILD_SPENDSAGE_DEBUG_SKIP_SPLASH=1
