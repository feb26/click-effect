#!/usr/bin/env bash
#
# Build ClickEffect.app from the Swift Package.
#
# Usage:
#   ./build-app.sh          # arm64 only (fast, for local dev)
#   ./build-app.sh --universal   # arm64 + x86_64 (for distribution)

set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="ClickEffect"
BUNDLE_DIR="build/${APP_NAME}.app"
CONTENTS_DIR="${BUNDLE_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

ARCH_ARGS=("--arch" "arm64")
if [[ "${1:-}" == "--universal" ]]; then
    ARCH_ARGS=("--arch" "arm64" "--arch" "x86_64")
fi

echo "==> Building (release, ${ARCH_ARGS[*]})"
swift build -c release "${ARCH_ARGS[@]}"

BIN_PATH=$(swift build -c release "${ARCH_ARGS[@]}" --show-bin-path)
BINARY="${BIN_PATH}/${APP_NAME}"

if [[ ! -f "${BINARY}" ]]; then
    echo "error: built binary not found at ${BINARY}" >&2
    exit 1
fi

echo "==> Assembling ${BUNDLE_DIR}"
rm -rf "${BUNDLE_DIR}"
mkdir -p "${MACOS_DIR}" "${RESOURCES_DIR}"

cp "${BINARY}" "${MACOS_DIR}/${APP_NAME}"
cp "Resources/Info.plist" "${CONTENTS_DIR}/Info.plist"

# Icon (optional — only bundled if the iconset exists).
if [[ -d "Resources/AppIcon.iconset" ]]; then
    echo "==> Generating AppIcon.icns"
    iconutil -c icns -o "${RESOURCES_DIR}/AppIcon.icns" "Resources/AppIcon.iconset"
fi

echo "==> Ad-hoc signing"
codesign --force --deep --sign - "${BUNDLE_DIR}"

# Clear quarantine on the locally built bundle so `open` works without prompt.
xattr -cr "${BUNDLE_DIR}" || true

echo ""
echo "Built: ${BUNDLE_DIR}"
echo "Run:   open ${BUNDLE_DIR}"
