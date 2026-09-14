#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
swift test --package-path Core
xcodebuild -project FinanceBuddy.xcodeproj -scheme FinanceBuddy \
  -configuration Debug -destination "${FINANCE_BUDDY_TEST_DESTINATION:-platform=iOS Simulator,name=iPhone 17e}" \
  -parallel-testing-enabled NO test
