#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

APP_SCHEME="LLMComparisonApp"
APP_BUNDLE_NAME="${APP_SCHEME}.app"
DMG_NAME="MultiLLMApp.dmg"
OUTPUT_DIR="${REPO_ROOT}/build"
DERIVED_DATA="${OUTPUT_DIR}/DerivedData"
DMG_OUTPUT_PATH="${OUTPUT_DIR}/${DMG_NAME}"
SWIFT_APP_PATH="${REPO_ROOT}/.build/apple/Products/Release/${APP_BUNDLE_NAME}"
XCODE_APP_PATH="${DERIVED_DATA}/Build/Products/Release/${APP_BUNDLE_NAME}"
APP_OUTPUT_PATH="${OUTPUT_DIR}/${APP_BUNDLE_NAME}"

cd "${REPO_ROOT}"
rm -rf "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}"

# First attempt SwiftPM build (works without an Xcode project)
swift build \
  --configuration release \
  --product "${APP_SCHEME}" \
  --arch arm64 || true

# If SwiftPM did not produce an .app (older toolchains), fall back to xcodebuild
if [[ ! -d "${SWIFT_APP_PATH}" ]]; then
  xcodebuild \
    -scheme "${APP_SCHEME}" \
    -configuration Release \
    -destination 'platform=macOS' \
    -derivedDataPath "${DERIVED_DATA}" \
    -skipPackagePluginValidation \
    -skipMacroValidation \
    clean build
fi

if [[ -d "${SWIFT_APP_PATH}" ]]; then
  APP_SOURCE_PATH="${SWIFT_APP_PATH}"
elif [[ -d "${XCODE_APP_PATH}" ]]; then
  APP_SOURCE_PATH="${XCODE_APP_PATH}"
else
  echo "Error: Built app not found. SwiftPM path: ${SWIFT_APP_PATH}, Xcode path: ${XCODE_APP_PATH}" >&2
  exit 1
fi

cp -R "${APP_SOURCE_PATH}" "${APP_OUTPUT_PATH}"
rm -f "${DMG_OUTPUT_PATH}"

hdiutil create \
  -volname "${APP_SCHEME}" \
  -srcfolder "${APP_OUTPUT_PATH}" \
  -ov \
  -format UDZO \
  "${DMG_OUTPUT_PATH}"

echo "DMG created at ${DMG_OUTPUT_PATH}"
