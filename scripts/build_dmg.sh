#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

APP_SCHEME="LLMComparisonApp"
DERIVED_DATA="${REPO_ROOT}/build/DerivedData"
OUTPUT_DIR="${REPO_ROOT}/build"
DMG_NAME="MultiLLMApp.dmg"
APP_BUNDLE_NAME="${APP_SCHEME}.app"
PRODUCTS_DIR="${DERIVED_DATA}/Build/Products/Release"
APP_SOURCE_PATH="${PRODUCTS_DIR}/${APP_BUNDLE_NAME}"
APP_OUTPUT_PATH="${OUTPUT_DIR}/${APP_BUNDLE_NAME}"
DMG_OUTPUT_PATH="${OUTPUT_DIR}/${DMG_NAME}"

rm -rf "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}"

xcodebuild \
  -scheme "${APP_SCHEME}" \
  -configuration Release \
  -destination 'platform=macOS' \
  -derivedDataPath "${DERIVED_DATA}" \
  clean build

if [[ ! -d "${APP_SOURCE_PATH}" ]]; then
  echo "Error: Built app not found at ${APP_SOURCE_PATH}" >&2
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
