#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECT_PATH="$ROOT_DIR/SpendSage.xcodeproj"
SCHEME="SpendSage"
BUILD_DIR="$ROOT_DIR/build"
MODE="${1:-internal}"

if [[ "$MODE" != "internal" && "$MODE" != "external" ]]; then
  echo "Usage: $0 [internal|external]" >&2
  exit 1
fi

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "xcodegen is required." >&2
  exit 1
fi

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "xcodebuild is required." >&2
  exit 1
fi

marketing_version="$(awk -F': ' '/MARKETING_VERSION:/ {print $2; exit}' "$ROOT_DIR/project.yml" | tr -d '\"')"
build_number="$(awk -F': ' '/CURRENT_PROJECT_VERSION:/ {print $2; exit}' "$ROOT_DIR/project.yml" | tr -d '\"')"
archive_path="$BUILD_DIR/SpendSage-${marketing_version}-${build_number}.xcarchive"
export_path="$BUILD_DIR/export-${MODE}-${build_number}"

if [[ "$MODE" == "internal" ]]; then
  export_options="$BUILD_DIR/ExportOptions-TestFlight-Internal.plist"
else
  export_options="$BUILD_DIR/ExportOptions-TestFlight-External.plist"
fi

mkdir -p "$BUILD_DIR"
rm -rf "$archive_path" "$export_path"

cd "$ROOT_DIR"
xcodegen generate

xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -allowProvisioningUpdates \
  archive \
  -archivePath "$archive_path"

xcodebuild \
  -exportArchive \
  -allowProvisioningUpdates \
  -archivePath "$archive_path" \
  -exportPath "$export_path" \
  -exportOptionsPlist "$export_options"

cat <<EOF
Upload submitted:
- mode: $MODE
- archive: $archive_path
- export: $export_path
EOF
