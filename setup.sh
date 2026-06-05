#!/bin/bash
set -e
cd "$(dirname "$0")"
if ! command -v xcodegen &>/dev/null; then
  echo "Installing XcodeGen..."
  brew install xcodegen
fi
xcodegen generate
echo "Done. Open MedFleet.xcodeproj in Xcode:"
echo "  open MedFleet.xcodeproj"
