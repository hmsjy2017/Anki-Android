import Foundation

/// Stable Swift boundary for the official Anki Rust backend.
///
/// Production iOS/iPadOS builds should provide an implementation backed by the
/// Anki Rust backend FFI layer. Keeping scheduling behind this protocol prevents
/// SwiftUI screens from reimplementing or diverging from Anki's scheduler.
public protocol AnkiRustBackend: Sendable {
    func openCollection(at url: URL) async throws -> CollectionHandle
    func nextReviewCard(in collection: CollectionHandle) async throws -> ReviewCard?
    func answerCard(
        _ card: ReviewCard,
        with rating: ReviewRating,
        in collection: CollectionHandle
    ) async throws -> ReviewOutcome
}

public struct CollectionHandle: Hashable, Sendable {
    public let rawValue: Int64

    public init(rawValue: Int64) {
        self.rawValue = rawValue
    }
}

public struct ReviewCard: Identifiable, Equatable, Sendable {
    public let id: Int64
    public let deckID: Int64
    public let frontHTML: String
    public let backHTML: String

    public init(id: Int64, deckID: Int64, frontHTML: String, backHTML: String) {
        self.id = id
        self.deckID = deckID
        self.frontHTML = frontHTML
        self.backHTML = backHTML
    }
}

public enum ReviewRating: Int, CaseIterable, Sendable {
    case again = 1
    case hard = 2
    case good = 3
    case easy = 4
}

public struct ReviewOutcome: Equatable, Sendable {
    public let cardID: Int64
    public let rating: ReviewRating
    public let nextReviewDate: Date

    public init(cardID: Int64, rating: ReviewRating, nextReviewDate: Date) {
        self.cardID = cardID
        self.rating = rating
        self.nextReviewDate = nextReviewDate
    }
}
