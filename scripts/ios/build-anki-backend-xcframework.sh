#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BRIDGE_DIR="$ROOT_DIR/ios/AnkiBackendBridge"
BUILD_DIR="$BRIDGE_DIR/build"
FRAMEWORK_DIR="$BUILD_DIR/AnkiBackendFFI.xcframework"
HEADER_DIR="$BRIDGE_DIR/include"
LIB_NAME="libanki_backend_bridge.a"

if ! command -v cargo >/dev/null 2>&1; then
  echo "cargo is required to build the official Anki Rust backend bridge" >&2
  exit 1
fi

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "xcodebuild is required to package the iOS XCFramework" >&2
  exit 1
fi

rustup target add aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios || true

rm -rf "$FRAMEWORK_DIR"
mkdir -p "$BUILD_DIR"

cargo build --manifest-path "$BRIDGE_DIR/Cargo.toml" --release --target aarch64-apple-ios
cargo build --manifest-path "$BRIDGE_DIR/Cargo.toml" --release --target aarch64-apple-ios-sim
cargo build --manifest-path "$BRIDGE_DIR/Cargo.toml" --release --target x86_64-apple-ios

SIM_UNIVERSAL="$BUILD_DIR/$LIB_NAME"
lipo -create \
  "$BRIDGE_DIR/target/aarch64-apple-ios-sim/release/$LIB_NAME" \
  "$BRIDGE_DIR/target/x86_64-apple-ios/release/$LIB_NAME" \
  -output "$SIM_UNIVERSAL"

xcodebuild -create-xcframework \
  -library "$BRIDGE_DIR/target/aarch64-apple-ios/release/$LIB_NAME" -headers "$HEADER_DIR" \
  -library "$SIM_UNIVERSAL" -headers "$HEADER_DIR" \
  -output "$FRAMEWORK_DIR"

echo "Built $FRAMEWORK_DIR"
