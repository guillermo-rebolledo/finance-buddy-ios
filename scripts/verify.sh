#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
release_settings=$(mktemp)
trap 'rm -f "$release_settings"' EXIT
xcodebuild -project FinanceBuddy.xcodeproj -scheme FinanceBuddy \
  -configuration Release -destination 'generic/platform=iOS Simulator' build
xcodebuild -project FinanceBuddy.xcodeproj -scheme FinanceBuddy \
  -configuration Release -destination 'generic/platform=iOS Simulator' \
  -showBuildSettings -json > "$release_settings"
python3 scripts/check-release.py "$release_settings"
swift test --package-path Core
xcodebuild -project FinanceBuddy.xcodeproj -scheme FinanceBuddy \
  -configuration Debug -destination "${FINANCE_BUDDY_TEST_DESTINATION:-platform=iOS Simulator,name=iPhone 17e}" \
  -parallel-testing-enabled NO test
