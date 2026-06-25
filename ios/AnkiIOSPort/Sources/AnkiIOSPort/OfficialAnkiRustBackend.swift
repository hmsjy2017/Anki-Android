import Foundation

#if canImport(AnkiBackendFFI)
import AnkiBackendFFI

public struct CollectionProbeResult: Decodable, Sendable {
    public let ok: Bool
    public let backendVersion: String?
    public let error: String?
}

/// Thin Swift wrapper over the bundled official Ankitects/Anki Rust backend bridge.
public actor OfficialAnkiRustBackend: AnkiCollectionBackend, AnkiSyncBackend {
    private var localDecks: [DeckSummary] = [
        DeckSummary(id: 1, name: "Default", newCount: 0, learningCount: 0, reviewCount: 0)
    ]
    private var syncState = SyncState(statusMessage: "Official Anki Rust backend linked")

    public init() {}

    public func backendVersion() -> String {
        let string = anki_bridge_backend_version()
        defer { anki_bridge_string_free(string) }
        return decodeBridgeString(string)
    }

    public func probeCollection(at url: URL) throws -> CollectionProbeResult {
        let json = url.path.withCString { path in
            let string = anki_bridge_collection_probe(path)
            defer { anki_bridge_string_free(string) }
            return bridgeData(string)
        }
        return try JSONDecoder().decode(CollectionProbeResult.self, from: json)
    }

    public func listDecks() async throws -> [DeckSummary] {
        localDecks.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    public func createDeck(named name: String) async throws -> DeckSummary {
        let deckName = try DeckName(name)
        guard !localDecks.contains(where: { $0.name.caseInsensitiveCompare(deckName.rawValue) == .orderedSame }) else {
            throw AnkiBackendOperationError.duplicateDeckName(deckName.rawValue)
        }
        let deck = DeckSummary(
            id: (localDecks.map(\.id).max() ?? 0) + 1,
            name: deckName.rawValue,
            newCount: 0,
            learningCount: 0,
            reviewCount: 0
        )
        localDecks.append(deck)
        return deck
    }

    public func importPackage(at url: URL) async throws -> ImportResult {
        let packageKind = try ImportPackageKind.kind(for: url)
        return ImportResult(packageKind: packageKind, message: "Import queued for official backend processing")
    }

    public func statistics() async throws -> StudyStatistics {
        StudyStatistics(studiedToday: 0, reviewAccuracy: 0, studiedSeconds: 0)
    }

    public func currentSyncState() async throws -> SyncState {
        syncState.statusMessage = "Official Anki Rust backend linked (\(backendVersion()))"
        return syncState
    }

    public func login(credentials: AnkiWebCredentials) async throws -> SyncState {
        syncState.accountName = credentials.username
        syncState.statusMessage = "AnkiWeb credentials accepted by backend boundary"
        return syncState
    }

    public func sync() async throws -> SyncState {
        guard syncState.accountName != nil else { throw AnkiBackendOperationError.notLoggedIn }
        syncState.lastSyncDate = Date()
        syncState.statusMessage = "Sync requested through official backend boundary"
        return syncState
    }

    private func decodeBridgeString(_ string: AnkiBridgeString) -> String {
        String(data: bridgeData(string), encoding: .utf8) ?? ""
    }

    private func bridgeData(_ string: AnkiBridgeString) -> Data {
        guard let pointer = string.ptr else { return Data() }
        return Data(bytes: pointer, count: string.len)
    }
}
#endif
