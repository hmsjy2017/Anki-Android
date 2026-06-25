#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BRIDGE_DIR="$ROOT_DIR/ios/AnkiBackendBridge"
BUILD_DIR="$BRIDGE_DIR/build"
FRAMEWORK_DIR="$BUILD_DIR/AnkiBackendFFI.xcframework"
HEADER_DIR="$BRIDGE_DIR/include"
LIB_NAME="libanki_backend_bridge.a"
PROTOC_VERSION="${IOS_PROTOC_VERSION:-27.3}"
PROTOC_DIR="$BUILD_DIR/protoc-$PROTOC_VERSION"

if ! command -v cargo >/dev/null 2>&1; then
  echo "cargo is required to build the official Anki Rust backend bridge" >&2
  exit 1
fi

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "xcodebuild is required to package the iOS XCFramework" >&2
  exit 1
fi

ensure_protoc() {
  if [[ -n "${PROTOC:-}" ]]; then
    if [[ -x "$PROTOC" ]]; then
      echo "Using PROTOC=$PROTOC"
      return
    fi
    echo "PROTOC is set to '$PROTOC', but that file is not executable" >&2
    exit 1
  fi

  if command -v protoc >/dev/null 2>&1; then
    PROTOC="$(command -v protoc)"
    export PROTOC
    echo "Using protoc from PATH: $PROTOC"
    return
  fi

  local os
  local arch
  local archive_platform
  os="$(uname -s)"
  arch="$(uname -m)"

  case "$os:$arch" in
    Darwin:arm64) archive_platform="osx-aarch_64" ;;
    Darwin:x86_64) archive_platform="osx-x86_64" ;;
    Linux:x86_64) archive_platform="linux-x86_64" ;;
    Linux:aarch64|Linux:arm64) archive_platform="linux-aarch_64" ;;
    *)
      echo "Could not find protoc and no bundled download is configured for $os/$arch." >&2
      echo "Install protobuf or set PROTOC=/path/to/protoc, then rerun this script." >&2
      exit 1
      ;;
  esac

  local protoc_bin="$PROTOC_DIR/bin/protoc"
  if [[ ! -x "$protoc_bin" ]]; then
    local zip_name="protoc-${PROTOC_VERSION}-${archive_platform}.zip"
    local url="https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VERSION}/${zip_name}"
    local zip_path="$BUILD_DIR/$zip_name"

    mkdir -p "$PROTOC_DIR"
    echo "protoc was not found; downloading $url"
    curl --fail --location --retry 3 --output "$zip_path" "$url"
    unzip -q -o "$zip_path" -d "$PROTOC_DIR"
    chmod +x "$protoc_bin"
  fi

  PROTOC="$protoc_bin"
  export PROTOC
  echo "Using downloaded protoc: $PROTOC"
}

mkdir -p "$BUILD_DIR"
ensure_protoc

rustup target add aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios || true

rm -rf "$FRAMEWORK_DIR"

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
