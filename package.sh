#!/usr/bin/env bash
#
# Build a Universal (arm64 + x86_64) ClickEffect.app and package it as a
# zip ready for distribution to coworkers.
#
# Output: build/ClickEffect-<version>.zip

set -euo pipefail
cd "$(dirname "$0")"

./build-app.sh --universal

VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" \
    "build/ClickEffect.app/Contents/Info.plist")
ZIP="build/ClickEffect-${VERSION}.zip"

rm -f "${ZIP}"

echo "==> Zipping ${ZIP}"
# Use ditto so macOS metadata (resource forks, code signature) is preserved.
( cd build && ditto -c -k --sequesterRsrc --keepParent \
    "ClickEffect.app" "ClickEffect-${VERSION}.zip" )

echo ""
echo "Built: ${ZIP}"
echo "Size:  $(du -h "${ZIP}" | cut -f1)"
echo ""
echo "Share this zip with coworkers along with the install instructions"
echo "from README.md (right-click → Open on first launch)."
