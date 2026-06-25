import Foundation

public actor ReviewSession {
    private let backend: any AnkiRustBackend
    private let collection: CollectionHandle

    public init(backend: any AnkiRustBackend, collectionURL: URL) async throws {
        self.backend = backend
        self.collection = try await backend.openCollection(at: collectionURL)
    }

    public func nextCard() async throws -> ReviewCard? {
        try await backend.nextReviewCard(in: collection)
    }

    @discardableResult
    public func answer(_ card: ReviewCard, with rating: ReviewRating) async throws -> ReviewOutcome {
        try await backend.answerCard(card, with: rating, in: collection)
    }
}
