import Foundation

public struct DeckSummary: Identifiable, Equatable, Sendable {
    public let id: Int64
    public var name: String
    public var newCount: Int
    public var learningCount: Int
    public var reviewCount: Int

    public init(id: Int64, name: String, newCount: Int, learningCount: Int, reviewCount: Int) {
        self.id = id
        self.name = name
        self.newCount = newCount
        self.learningCount = learningCount
        self.reviewCount = reviewCount
    }

    public var dueCount: Int { newCount + learningCount + reviewCount }
}

public struct SyncState: Equatable, Sendable {
    public var isSignedIn: Bool
    public var accountName: String?
    public var lastSyncDate: Date?
    public var pendingChanges: Int
    public var statusMessage: String

    public init(isSignedIn: Bool = false, accountName: String? = nil, lastSyncDate: Date? = nil, pendingChanges: Int = 0, statusMessage: String = "Not synced yet") {
        self.isSignedIn = isSignedIn
        self.accountName = accountName
        self.lastSyncDate = lastSyncDate
        self.pendingChanges = pendingChanges
        self.statusMessage = statusMessage
    }
}

public actor DeckLibrary {
    private var decks: [DeckSummary]

    public init(decks: [DeckSummary] = DeckLibrary.sampleDecks) {
        self.decks = decks
    }

    public func listDecks() -> [DeckSummary] {
        decks.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    public func addDeck(named name: String) throws -> DeckSummary {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw DeckLibraryError.emptyName }
        guard !decks.contains(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) else {
            throw DeckLibraryError.duplicateName(trimmed)
        }
        let nextID = (decks.map(\.id).max() ?? 0) + 1
        let deck = DeckSummary(id: nextID, name: trimmed, newCount: 0, learningCount: 0, reviewCount: 0)
        decks.append(deck)
        return deck
    }

    public static let sampleDecks = [
        DeckSummary(id: 1, name: "Default", newCount: 12, learningCount: 3, reviewCount: 25),
        DeckSummary(id: 2, name: "Japanese", newCount: 8, learningCount: 2, reviewCount: 14),
        DeckSummary(id: 3, name: "Biology", newCount: 5, learningCount: 0, reviewCount: 9)
    ]
}

public enum DeckLibraryError: Error, Equatable, LocalizedError {
    case emptyName
    case duplicateName(String)

    public var errorDescription: String? {
        switch self {
        case .emptyName: "Deck name cannot be empty."
        case let .duplicateName(name): "A deck named ‘\(name)’ already exists."
        }
    }
}

public actor SyncCoordinator {
    private var state: SyncState

    public init(state: SyncState = SyncState(pendingChanges: 3)) {
        self.state = state
    }

    public func currentState() -> SyncState { state }

    public func signIn(accountName: String) throws -> SyncState {
        let trimmed = accountName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw SyncError.emptyAccountName }
        state.isSignedIn = true
        state.accountName = trimmed
        state.statusMessage = "Signed in as \(trimmed)"
        return state
    }

    public func sync(now: Date = Date()) throws -> SyncState {
        guard state.isSignedIn else { throw SyncError.notSignedIn }
        state.lastSyncDate = now
        state.pendingChanges = 0
        state.statusMessage = "Sync complete"
        return state
    }
}

public enum SyncError: Error, Equatable, LocalizedError {
    case emptyAccountName
    case notSignedIn

    public var errorDescription: String? {
        switch self {
        case .emptyAccountName: "Enter an AnkiWeb account name."
        case .notSignedIn: "Sign in before syncing."
        }
    }
}
