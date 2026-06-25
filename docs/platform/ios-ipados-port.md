# iOS/iPadOS Port Plan

This document defines the compatibility target and delivery checklist for a feature-complete AnkiDroid port to iOS and iPadOS.

A full iOS/iPadOS port is a product-scale effort, not a single patch. The repository currently contains Android modules and shared library code, so the first mergeable step is to make the expected scope, compatibility rules, and CI entry point explicit before adding native Apple targets.

## Compatibility target

The iOS/iPadOS port must preserve the user-visible behavior of AnkiDroid unless a difference is explicitly documented and accepted by maintainers.

Required platform targets:

- iPhone and iPad form factors.
- Current iOS and iPadOS releases supported by Apple, plus the oldest deployment target chosen by maintainers for the first TestFlight release.
- Hardware keyboard, touch, split-screen, rotation, Dynamic Type, VoiceOver, and system dark mode where applicable.

## Feature-complete checklist

The port is not considered feature-complete until these areas are implemented, tested, and documented:

- Collection open, close, backup, restore, import, and export flows.
- Deck list, overview, study, review, bury, suspend, flag, mark, and undo behavior.
- Note editor, card browser, filtered decks, custom study, statistics, preferences, and media handling.
- Sync compatibility with AnkiWeb and existing collection/media state.
- Add-on or JavaScript-facing behavior that is part of supported AnkiDroid functionality.
- Localization and right-to-left layout behavior matching the Android app where possible.
- Accessibility coverage for critical study, edit, sync, and navigation flows.
- Crash reporting, analytics policy compliance, privacy disclosures, and release signing.

## Architecture requirements

The preferred migration path is incremental sharing rather than a one-shot rewrite:

1. Keep existing Android behavior stable while extracting platform-neutral logic behind interfaces.
2. Reuse shared collection/scheduler behavior from existing shared modules where possible.
3. Add Apple-specific UI, storage, background task, notification, and file provider integrations in an isolated iOS app target.
4. Add parity tests for every migrated feature before removing Android-only assumptions from shared code.

Native iOS code should live under an `ios/` directory unless maintainers choose a different layout. The directory should include an Xcode workspace or project, Swift package configuration when needed, and Apple-specific test targets.

## GitHub Actions build contract

The `iOS / iPadOS` workflow is intentionally safe before the native app target exists:

- If no Xcode workspace or project is present under `ios/`, CI records a notice and exits successfully.
- Once `ios/*.xcworkspace` or `ios/*.xcodeproj` exists, CI resolves Swift package dependencies when applicable, builds the configured scheme, and runs tests on an iPad simulator.
- The default scheme is `AnkiDroid`, but maintainers can override it with the `IOS_SCHEME` repository variable.

This keeps pull requests green today while ensuring that the first native iOS project added to the repository is automatically built by GitHub Actions.

## Definition of done for first iOS beta

Before a first TestFlight beta, maintainers should require:

- A passing GitHub Actions iOS build and test run.
- A documented feature parity matrix with all unsupported behavior called out.
- Manual smoke tests on at least one iPhone and one iPad device.
- Verified sync round trips against existing AnkiWeb collections containing scheduling state, media, custom note types, and filtered decks.
- A release checklist covering signing, provisioning, privacy manifests, App Store metadata, and rollback procedures.
