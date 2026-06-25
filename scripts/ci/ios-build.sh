#!/usr/bin/env bash
set -euo pipefail

IOS_DIR="${IOS_DIR:-ios}"
SCHEME="${IOS_SCHEME:-AnkiDroid}"
DESTINATION="${IOS_DESTINATION:-generic/platform=iOS Simulator}"
SWIFT_PACKAGE_PATH="${IOS_SWIFT_PACKAGE_PATH:-}"

if [[ ! -d "$IOS_DIR" ]]; then
  echo "::notice title=iOS build skipped::No '$IOS_DIR' directory exists yet. Add the native iOS/iPadOS project under '$IOS_DIR' to enable builds."
  exit 0
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

if [[ -n "$SWIFT_PACKAGE_PATH" ]]; then
  if [[ -f "$SWIFT_PACKAGE_PATH/Package.swift" ]]; then
    package="$SWIFT_PACKAGE_PATH"
  else
    echo "::error title=iOS Swift package missing::IOS_SWIFT_PACKAGE_PATH='$SWIFT_PACKAGE_PATH' does not contain Package.swift."
    exit 1
  fi
else
  while IFS= read -r -d '' candidate; do
    package="$(dirname "$candidate")"
    break
  done < <(find "$IOS_DIR" -maxdepth 2 -name 'Package.swift' -print0 | sort -z)
fi

if [[ -z "$workspace" && -z "$project" && -z "$package" ]]; then
  echo "::notice title=iOS build skipped::No Xcode workspace, Xcode project, or Swift package was found under '$IOS_DIR'."
  exit 0
fi

if [[ -n "$workspace" ]]; then
  xcodebuild -resolvePackageDependencies -workspace "$workspace" -scheme "$SCHEME"
  xcodebuild build -workspace "$workspace" -scheme "$SCHEME" -destination "$DESTINATION"
elif [[ -n "$project" ]]; then
  xcodebuild -resolvePackageDependencies -project "$project" -scheme "$SCHEME"
  xcodebuild build -project "$project" -scheme "$SCHEME" -destination "$DESTINATION"
fi

if [[ -n "$package" ]]; then
  swift test --package-path "$package"
fi
