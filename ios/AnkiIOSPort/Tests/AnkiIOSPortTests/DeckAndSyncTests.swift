import Foundation
import Testing
@testable import AnkiIOSPort

@Test func deckLibraryAddsAndSortsDecks() async throws {
    let library = DeckLibrary(decks: [
        DeckSummary(id: 10, name: "Zoology", newCount: 1, learningCount: 0, reviewCount: 0)
    ])

    let created = try await library.addDeck(named: "  Algebra  ")
    #expect(created.name == "Algebra")
    #expect(created.dueCount == 0)

    let decks = await library.listDecks()
    #expect(decks.map(\.name) == ["Algebra", "Zoology"])
}

@Test func deckLibraryRejectsInvalidDeckNames() async throws {
    let library = DeckLibrary(decks: [
        DeckSummary(id: 1, name: "Default", newCount: 0, learningCount: 0, reviewCount: 0)
    ])

    await #expect(throws: DeckLibraryError.emptyName) {
        try await library.addDeck(named: "   ")
    }

    await #expect(throws: DeckLibraryError.duplicateName("default")) {
        try await library.addDeck(named: "default")
    }
}

@Test func syncCoordinatorRequiresSignInThenClearsPendingChanges() async throws {
    let coordinator = SyncCoordinator(state: SyncState(pendingChanges: 4))

    #expect(await coordinator.currentState().pendingChanges == 4)
    await #expect(throws: SyncError.notSignedIn) {
        try await coordinator.sync(now: Date(timeIntervalSince1970: 100))
    }

    let signedIn = try await coordinator.signIn(accountName: " user@example.com ")
    #expect(signedIn.isSignedIn)
    #expect(signedIn.accountName == "user@example.com")

    let synced = try await coordinator.sync(now: Date(timeIntervalSince1970: 100))
    #expect(synced.pendingChanges == 0)
    #expect(synced.lastSyncDate == Date(timeIntervalSince1970: 100))
    #expect(synced.statusMessage == "Sync complete")
}
