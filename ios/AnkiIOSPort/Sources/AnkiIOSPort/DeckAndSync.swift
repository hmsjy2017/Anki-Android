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
    public var accountName: String?
    public var lastSyncDate: Date?
    public var pendingChanges: Int
    public var statusMessage: String

    public init(accountName: String? = nil, lastSyncDate: Date? = nil, pendingChanges: Int = 0, statusMessage: String = "Official Anki backend is not linked") {
        self.accountName = accountName
        self.lastSyncDate = lastSyncDate
        self.pendingChanges = pendingChanges
        self.statusMessage = statusMessage
    }
}

public struct AnkiWebCredentials: Equatable, Sendable {
    public let username: String
    public let password: String

    public init(username: String, password: String) throws {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedUsername.isEmpty else { throw AnkiBackendOperationError.emptyUsername }
        guard !password.isEmpty else { throw AnkiBackendOperationError.emptyPassword }
        self.username = trimmedUsername
        self.password = password
    }
}

public enum ImportPackageKind: Equatable, Sendable {
    case deckPackage
    case collectionPackage

    public static func kind(for url: URL) throws -> ImportPackageKind {
        switch url.pathExtension.lowercased() {
        case "apkg": .deckPackage
        case "colpkg": .collectionPackage
        default: throw AnkiBackendOperationError.unsupportedPackageExtension(url.pathExtension)
        }
    }
}

public struct ImportResult: Equatable, Sendable {
    public let packageKind: ImportPackageKind
    public let message: String

    public init(packageKind: ImportPackageKind, message: String) {
        self.packageKind = packageKind
        self.message = message
    }
}

public struct StudyStatistics: Equatable, Sendable {
    public var studiedToday: Int
    public var reviewAccuracy: Double
    public var studiedSeconds: Int

    public init(studiedToday: Int, reviewAccuracy: Double, studiedSeconds: Int) {
        self.studiedToday = studiedToday
        self.reviewAccuracy = reviewAccuracy
        self.studiedSeconds = studiedSeconds
    }
}

public protocol AnkiCollectionBackend: Sendable {
    func listDecks() async throws -> [DeckSummary]
    func createDeck(named name: String) async throws -> DeckSummary
    func importPackage(at url: URL) async throws -> ImportResult
    func statistics() async throws -> StudyStatistics
}

public protocol AnkiSyncBackend: Sendable {
    func currentSyncState() async throws -> SyncState
    func login(credentials: AnkiWebCredentials) async throws -> SyncState
    func sync() async throws -> SyncState
}

/// Explicit placeholder used until the official Anki Rust backend is packaged for Apple platforms.
///
/// This type intentionally does not fake AnkiWeb login, syncing, importing, scheduling, or statistics.
/// Production iOS/iPadOS builds must replace it with an implementation backed by the official
/// Anki Rust backend FFI/XCFramework so behavior matches Anki Desktop and AnkiDroid.
public actor OfficialAnkiBackendUnavailable: AnkiCollectionBackend, AnkiSyncBackend {
    public init() {}

    public func listDecks() async throws -> [DeckSummary] {
        throw AnkiBackendOperationError.officialBackendNotLinked
    }

    public func createDeck(named name: String) async throws -> DeckSummary {
        _ = try DeckName(name)
        throw AnkiBackendOperationError.officialBackendNotLinked
    }

    public func importPackage(at url: URL) async throws -> ImportResult {
        _ = try ImportPackageKind.kind(for: url)
        throw AnkiBackendOperationError.officialBackendNotLinked
    }

    public func statistics() async throws -> StudyStatistics {
        throw AnkiBackendOperationError.officialBackendNotLinked
    }

    public func currentSyncState() async throws -> SyncState {
        SyncState(statusMessage: AnkiBackendOperationError.officialBackendNotLinked.localizedDescription)
    }

    public func login(credentials: AnkiWebCredentials) async throws -> SyncState {
        throw AnkiBackendOperationError.officialBackendNotLinked
    }

    public func sync() async throws -> SyncState {
        throw AnkiBackendOperationError.officialBackendNotLinked
    }
}

public struct DeckName: Equatable, Sendable {
    public let rawValue: String

    public init(_ name: String) throws {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw AnkiBackendOperationError.emptyDeckName }
        self.rawValue = trimmed
    }
}

public enum AnkiBackendOperationError: Error, Equatable, LocalizedError {
    case emptyDeckName
    case emptyUsername
    case emptyPassword
    case unsupportedPackageExtension(String)
    case officialBackendNotLinked

    public var errorDescription: String? {
        switch self {
        case .emptyDeckName:
            "Deck name cannot be empty."
        case .emptyUsername:
            "Enter your AnkiWeb username."
        case .emptyPassword:
            "Enter your AnkiWeb password."
        case let .unsupportedPackageExtension(ext):
            "Only .apkg deck packages and .colpkg collection packages are supported, not .\(ext)."
        case .officialBackendNotLinked:
            "The official Anki Rust backend is not linked in this build yet."
        }
    }
}
