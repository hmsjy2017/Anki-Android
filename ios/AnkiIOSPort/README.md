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


## Official Anki Rust backend bridge

The iOS port now includes a Rust FFI bridge crate at `ios/AnkiBackendBridge` that depends directly on the official `ankitects/anki` Rust crate (`rslib`) at tag `26.05`. Build it on macOS with:

```bash
scripts/ios/build-anki-backend-xcframework.sh
```

The script cross-compiles the Rust bridge for iOS device and simulator targets and creates `ios/AnkiBackendBridge/build/AnkiBackendFFI.xcframework`. When that XCFramework exists, `ios/AnkiIOSPort/Package.swift` automatically adds it as the `AnkiBackendFFI` binary target so Swift code can call the C FFI wrapper. The first exposed calls report the upstream backend version and perform an official `CollectionBuilder` open/close probe against a collection path; higher-level deck, review, sync, import, and statistics calls should be layered on this same bridge instead of being reimplemented in Swift.

## IPA packaging

The repository now includes a minimal SwiftUI app target and shared Xcode scheme at
`ios/AnkiDroid` that depend on this Swift package. CI builds the app and packages an unsigned IPA on
every iOS workflow run, including pull requests and pushes to `main`, so manual
workflow dispatch is not required for routine packaging checks.

Run `IOS_UNSIGNED_IPA=true scripts/ci/ios-package.sh` on macOS with Xcode to
archive the app and zip the unsigned `Payload/AnkiDroid.app` into
`build/ios/ipa/AnkiDroid-unsigned.ipa`. For signed distribution, provide signing
credentials and export options, then run `scripts/ci/ios-package.sh` without
`IOS_UNSIGNED_IPA=true`.
