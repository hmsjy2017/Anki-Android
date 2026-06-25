#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FLUTTER_DIR="$ROOT_DIR/ios/FlutterAnkiDroid"
OUTPUT_DIR="$FLUTTER_DIR/build/ios/framework"

if [[ ! -d "$FLUTTER_DIR" ]]; then
  echo "Flutter module directory '$FLUTTER_DIR' does not exist" >&2
  exit 1
fi

if ! command -v flutter >/dev/null 2>&1; then
  echo "flutter is required to build the AnkiDroid iOS Flutter module" >&2
  exit 1
fi

flutter --version
flutter pub get --directory "$FLUTTER_DIR"
flutter test "$FLUTTER_DIR"
flutter build ios-framework --no-profile --output "$OUTPUT_DIR" "$FLUTTER_DIR"

echo "Built Flutter iOS frameworks in $OUTPUT_DIR"
