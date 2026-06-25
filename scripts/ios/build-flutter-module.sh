#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FLUTTER_DIR="$ROOT_DIR/ios/FlutterAnkiDroid"
OUTPUT_DIR="$FLUTTER_DIR/build/ios/framework"
FLUTTER_SDK_DIR="${IOS_FLUTTER_SDK_DIR:-$ROOT_DIR/build/ios/flutter-sdk}"
AUTO_INSTALL_FLUTTER="${IOS_FLUTTER_AUTO_INSTALL:-true}"
UNSIGNED_IPA="${IOS_UNSIGNED_IPA:-true}"

if [[ ! -d "$FLUTTER_DIR" ]]; then
  echo "Flutter module directory '$FLUTTER_DIR' does not exist" >&2
  exit 1
fi

ensure_flutter() {
  if [[ -n "${FLUTTER_BIN:-}" ]]; then
    if [[ -x "$FLUTTER_BIN" ]]; then
      echo "Using FLUTTER_BIN=$FLUTTER_BIN"
      return
    fi
    echo "FLUTTER_BIN is set to '$FLUTTER_BIN', but that file is not executable" >&2
    exit 1
  fi

  if command -v flutter >/dev/null 2>&1; then
    FLUTTER_BIN="$(command -v flutter)"
    export FLUTTER_BIN
    echo "Using flutter from PATH: $FLUTTER_BIN"
    return
  fi

  if [[ "$AUTO_INSTALL_FLUTTER" != "true" ]]; then
    echo "flutter is required to build the AnkiDroid iOS Flutter module" >&2
    echo "Install Flutter, set FLUTTER_BIN=/path/to/flutter, or allow IOS_FLUTTER_AUTO_INSTALL=true." >&2
    exit 1
  fi

  if [[ ! -x "$FLUTTER_SDK_DIR/bin/flutter" ]]; then
    if ! command -v git >/dev/null 2>&1; then
      echo "git is required to auto-install Flutter" >&2
      exit 1
    fi
    mkdir -p "$(dirname "$FLUTTER_SDK_DIR")"
    echo "flutter was not found; cloning Flutter stable SDK into $FLUTTER_SDK_DIR"
    git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "$FLUTTER_SDK_DIR"
  fi

  FLUTTER_BIN="$FLUTTER_SDK_DIR/bin/flutter"
  export FLUTTER_BIN
  export PATH="$FLUTTER_SDK_DIR/bin:$PATH"
  echo "Using auto-installed Flutter: $FLUTTER_BIN"
}

ensure_flutter

flutter_build_args=(ios-framework --no-profile --output "$OUTPUT_DIR")
if [[ "$UNSIGNED_IPA" == "true" ]]; then
  export CODE_SIGNING_ALLOWED=NO
  export CODE_SIGNING_REQUIRED=NO
  export CODE_SIGN_IDENTITY=""
fi

"$FLUTTER_BIN" --version
if [[ "$UNSIGNED_IPA" == "true" ]] && "$FLUTTER_BIN" build ios-framework --help | grep -q -- "--no-codesign"; then
  flutter_build_args+=(--no-codesign)
fi
(
  cd "$FLUTTER_DIR"
  if [[ ! -d ios ]]; then
    "$FLUTTER_BIN" create --platforms=ios --project-name flutter_ankidroid .
  fi
  rm -f test/widget_test.dart
  "$FLUTTER_BIN" pub get
  "$FLUTTER_BIN" test
  "$FLUTTER_BIN" build "${flutter_build_args[@]}"
)

echo "Built Flutter iOS frameworks in $OUTPUT_DIR"
