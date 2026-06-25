#!/usr/bin/env bash
set -euo pipefail

IOS_DIR="${IOS_DIR:-ios}"
SCHEME="${IOS_SCHEME:-AnkiDroid}"
CONFIGURATION="${IOS_CONFIGURATION:-Release}"
ARCHIVE_PATH="${IOS_ARCHIVE_PATH:-build/ios/${SCHEME}.xcarchive}"
EXPORT_PATH="${IOS_EXPORT_PATH:-build/ios/ipa}"
EXPORT_METHOD="${IOS_EXPORT_METHOD:-development}"
EXPORT_OPTIONS_PLIST="${IOS_EXPORT_OPTIONS_PLIST:-}"
DESTINATION="${IOS_ARCHIVE_DESTINATION:-generic/platform=iOS}"
ALLOW_PROVISIONING_UPDATES="${IOS_ALLOW_PROVISIONING_UPDATES:-false}"
UNSIGNED_IPA="${IOS_UNSIGNED_IPA:-true}"
BUILD_ANKI_BACKEND="${IOS_BUILD_ANKI_BACKEND:-true}"
BUILD_FLUTTER="${IOS_BUILD_FLUTTER:-true}"
ANKI_BACKEND_XCFRAMEWORK="ios/AnkiBackendBridge/build/AnkiBackendFFI.xcframework"

if [[ ! -d "$IOS_DIR" ]]; then
  echo "::error title=iOS packaging failed::No '$IOS_DIR' directory exists. Add the native iOS/iPadOS app target before packaging an IPA."
  exit 1
fi

workspace=""
project=""
package=""

while IFS= read -r -d '' candidate; do
  workspace="$candidate"
  break
done < <(find "$IOS_DIR" -maxdepth 2 -name '*.xcworkspace' -print0 | sort -z)

if [[ -z "$workspace" ]]; then
  while IFS= read -r -d '' candidate; do
    project="$candidate"
    break
  done < <(find "$IOS_DIR" -maxdepth 2 -name '*.xcodeproj' -print0 | sort -z)
fi

if [[ -z "$workspace" && -z "$project" ]]; then
  while IFS= read -r -d '' candidate; do
    package="$(dirname "$candidate")"
    break
  done < <(find "$IOS_DIR" -maxdepth 2 -name 'Package.swift' -print0 | sort -z)
fi

if [[ -z "$workspace" && -z "$project" ]]; then
  if [[ -n "$package" ]]; then
    echo "::error title=IPA packaging requires an app target::Found Swift package '$package', but Swift library packages do not produce installable .app bundles or .ipa files. Add an Xcode iOS app project/workspace under '$IOS_DIR' that depends on this package, then rerun this script."
  else
    echo "::error title=iOS packaging failed::No Xcode workspace or project was found under '$IOS_DIR'. Add an iOS app target before packaging an IPA."
  fi
  exit 1
fi

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "::error title=xcodebuild missing::Packaging an IPA requires macOS with Xcode command line tools."
  exit 1
fi

if [[ "$BUILD_FLUTTER" == "true" && -d "ios/FlutterAnkiDroid" ]]; then
  scripts/ios/build-flutter-module.sh
fi

if [[ "$BUILD_ANKI_BACKEND" == "true" ]]; then
  scripts/ios/build-anki-backend-xcframework.sh
fi

if [[ ! -d "$ANKI_BACKEND_XCFRAMEWORK" ]]; then
  echo "::error title=Anki backend missing::Expected '$ANKI_BACKEND_XCFRAMEWORK' before packaging. Run scripts/ios/build-anki-backend-xcframework.sh or set IOS_BUILD_ANKI_BACKEND=false only for temporary diagnostics."
  exit 1
fi

mkdir -p "$(dirname "$ARCHIVE_PATH")" "$EXPORT_PATH"

build_settings=()
if [[ "$UNSIGNED_IPA" == "true" ]]; then
  build_settings+=("CODE_SIGNING_ALLOWED=NO" "CODE_SIGNING_REQUIRED=NO" "CODE_SIGN_IDENTITY=")
fi

created_export_options=""
if [[ "$UNSIGNED_IPA" != "true" && -z "$EXPORT_OPTIONS_PLIST" ]]; then
  EXPORT_OPTIONS_PLIST="$(mktemp -t anki-ios-export-options.XXXXXX.plist)"
  created_export_options="$EXPORT_OPTIONS_PLIST"
  cat > "$EXPORT_OPTIONS_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>${EXPORT_METHOD}</string>
</dict>
</plist>
PLIST
fi

cleanup() {
  if [[ -n "$created_export_options" ]]; then
    rm -f "$created_export_options"
  fi
}
trap cleanup EXIT

xcode_args=()
if [[ "$ALLOW_PROVISIONING_UPDATES" == "true" ]]; then
  xcode_args+=("-allowProvisioningUpdates")
fi

archive_args=(
  archive
  -scheme "$SCHEME"
  -configuration "$CONFIGURATION"
  -destination "$DESTINATION"
  -archivePath "$ARCHIVE_PATH"
)

if [[ -n "$workspace" ]]; then
  archive_args+=(-workspace "$workspace")
else
  archive_args+=(-project "$project")
fi

if ((${#xcode_args[@]})); then
  archive_args+=("${xcode_args[@]}")
fi

if ((${#build_settings[@]})); then
  archive_args+=("${build_settings[@]}")
fi

xcodebuild "${archive_args[@]}"

if [[ "$UNSIGNED_IPA" == "true" ]]; then
  app=""
  while IFS= read -r -d '' candidate; do
    app="$candidate"
    break
  done < <(find "$ARCHIVE_PATH/Products/Applications" -maxdepth 1 -name '*.app' -print0 | sort -z)

  if [[ -z "$app" ]]; then
    echo "::error title=Unsigned IPA packaging failed::No .app bundle was found in '$ARCHIVE_PATH/Products/Applications'."
    exit 1
  fi

  if ! command -v zip >/dev/null 2>&1; then
    echo "::error title=zip missing::Packaging an unsigned IPA requires the zip command."
    exit 1
  fi

  unsigned_root="$(mktemp -d -t anki-ios-unsigned-ipa.XXXXXX)"
  ipa_name="${IOS_IPA_NAME:-${SCHEME}-unsigned.ipa}"
  export_path_absolute="$(cd "$EXPORT_PATH" && pwd)"
  mkdir -p "$unsigned_root/Payload"
  cp -R "$app" "$unsigned_root/Payload/"
  (
    cd "$unsigned_root"
    zip -qry "$export_path_absolute/$ipa_name" Payload
  )
  rm -rf "$unsigned_root"
  echo "Unsigned IPA export complete: $EXPORT_PATH/$ipa_name"
else
  export_args=(
    -exportArchive
    -archivePath "$ARCHIVE_PATH"
    -exportPath "$EXPORT_PATH"
    -exportOptionsPlist "$EXPORT_OPTIONS_PLIST"
  )

  if ((${#xcode_args[@]})); then
    export_args+=("${xcode_args[@]}")
  fi

  xcodebuild "${export_args[@]}"

  echo "IPA export complete: $EXPORT_PATH"
fi
