# Anki iOS/iPadOS Swift Port

This directory contains the initial compileable Swift package for an iOS/iPadOS
port of AnkiDroid concepts. The package deliberately keeps scheduling behind the
`AnkiRustBackend` protocol so the app delegates scheduling decisions to the
official Anki Rust backend instead of reimplementing scheduler logic in Swift.

## Current scope

- Swift Package Manager library target for iOS 17+, iPadOS 17+, and macOS 14+.
- A Swift concurrency-friendly backend boundary for opening collections, fetching
  the next review card, and answering cards.
- A `ReviewSession` actor that UI code can use without knowing backend FFI
  details.
- Tests proving review flow delegates scheduling operations through the backend
  abstraction.

## Next integration steps

1. Add an XCFramework or SwiftPM binary target that packages the official Anki
   Rust backend for Apple platforms.
2. Implement `AnkiRustBackend` with the generated C/Swift FFI bindings.
3. Build SwiftUI screens on top of `ReviewSession` and keep scheduler behavior in
   the Rust backend.
4. Expand coverage for collection loading, media paths, sync, and import/export.

## IPA packaging

The Swift package in this directory is a library boundary, so it can compile and
test by itself but cannot produce an installable IPA without an iOS app target.
Once an Xcode `.xcodeproj` or `.xcworkspace` app target is added under `ios/`, run
`IOS_SCHEME=<AppScheme> scripts/ci/ios-package.sh` on macOS with Xcode and valid
signing credentials to archive and export the IPA into `build/ios/ipa`. To create
an unsigned IPA for internal inspection, run
`IOS_UNSIGNED_IPA=true IOS_SCHEME=<AppScheme> scripts/ci/ios-package.sh`; this
disables code signing during archive and zips the archived `.app` as
`Payload/<App>.app`.
