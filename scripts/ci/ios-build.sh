#!/usr/bin/env bash
set -euo pipefail

IOS_DIR="${IOS_DIR:-ios}"
SCHEME="${IOS_SCHEME:-AnkiDroid}"
DESTINATION="${IOS_DESTINATION:-platform=iOS Simulator,name=iPad (10th generation)}"

if [[ ! -d "$IOS_DIR" ]]; then
  echo "::notice title=iOS build skipped::No '$IOS_DIR' directory exists yet. Add the native iOS/iPadOS project under '$IOS_DIR' to enable builds."
  exit 0
fi

workspace=""
project=""

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
  echo "::notice title=iOS build skipped::No Xcode workspace or project was found under '$IOS_DIR'."
  exit 0
fi

if [[ -n "$workspace" ]]; then
  xcodebuild -resolvePackageDependencies -workspace "$workspace" -scheme "$SCHEME"
  xcodebuild build test -workspace "$workspace" -scheme "$SCHEME" -destination "$DESTINATION"
else
  xcodebuild -resolvePackageDependencies -project "$project" -scheme "$SCHEME"
  xcodebuild build test -project "$project" -scheme "$SCHEME" -destination "$DESTINATION"
fi
