import Foundation
import Testing
@testable import AnkiIOSPort

@Test func deckNameTrimsAndRejectsEmptyNames() throws {
    #expect(try DeckName("  Japanese  ").rawValue == "Japanese")
    #expect(throws: AnkiBackendOperationError.emptyDeckName) {
        try DeckName("   ")
    }
}

@Test func ankiWebCredentialsRequireUsernameAndPassword() throws {
    let credentials = try AnkiWebCredentials(username: " user@example.com ", password: "secret")
    #expect(credentials.username == "user@example.com")
    #expect(credentials.password == "secret")

    #expect(throws: AnkiBackendOperationError.emptyUsername) {
        try AnkiWebCredentials(username: " ", password: "secret")
    }
    #expect(throws: AnkiBackendOperationError.emptyPassword) {
        try AnkiWebCredentials(username: "user@example.com", password: "")
    }
}

@Test func importPackageKindMatchesAnkiPackageExtensions() throws {
    #expect(try ImportPackageKind.kind(for: URL(fileURLWithPath: "/tmp/deck.apkg")) == .deckPackage)
    #expect(try ImportPackageKind.kind(for: URL(fileURLWithPath: "/tmp/collection.colpkg")) == .collectionPackage)
    #expect(throws: AnkiBackendOperationError.unsupportedPackageExtension("zip")) {
        try ImportPackageKind.kind(for: URL(fileURLWithPath: "/tmp/archive.zip"))
    }
}

@Test func unavailableBackendDoesNotFakeCollectionOrSyncOperations() async throws {
    let backend = OfficialAnkiBackendUnavailable()

    await #expect(throws: AnkiBackendOperationError.officialBackendNotLinked) {
        try await backend.listDecks()
    }
    await #expect(throws: AnkiBackendOperationError.officialBackendNotLinked) {
        try await backend.createDeck(named: "Default")
    }
    await #expect(throws: AnkiBackendOperationError.officialBackendNotLinked) {
        try await backend.importPackage(at: URL(fileURLWithPath: "/tmp/deck.apkg"))
    }
    await #expect(throws: AnkiBackendOperationError.officialBackendNotLinked) {
        let credentials = try AnkiWebCredentials(username: "user@example.com", password: "secret")
        _ = try await backend.login(credentials: credentials)
    }
    await #expect(throws: AnkiBackendOperationError.officialBackendNotLinked) {
        try await backend.sync()
    }

    let syncState = try await backend.currentSyncState()
    #expect(syncState.statusMessage == AnkiBackendOperationError.officialBackendNotLinked.localizedDescription)
}
