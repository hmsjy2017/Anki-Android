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
