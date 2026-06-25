import Foundation
import Testing
@testable import AnkiIOSPort

private actor MockRustBackend: AnkiRustBackend {
    private var cards: [ReviewCard]
    private(set) var answeredRatings: [ReviewRating] = []

    init(cards: [ReviewCard]) {
        self.cards = cards
    }

    func openCollection(at url: URL) async throws -> CollectionHandle {
        #expect(url.pathExtension == "anki2")
        return CollectionHandle(rawValue: 1)
    }

    func nextReviewCard(in collection: CollectionHandle) async throws -> ReviewCard? {
        #expect(collection.rawValue == 1)
        return cards.first
    }

    func answerCard(
        _ card: ReviewCard,
        with rating: ReviewRating,
        in collection: CollectionHandle
    ) async throws -> ReviewOutcome {
        #expect(collection.rawValue == 1)
        answeredRatings.append(rating)
        cards.removeAll { $0.id == card.id }
        return ReviewOutcome(cardID: card.id, rating: rating, nextReviewDate: Date(timeIntervalSince1970: 0))
    }
}

@Test func reviewSessionDelegatesSchedulingToRustBackendBoundary() async throws {
    let card = ReviewCard(id: 42, deckID: 7, frontHTML: "Front", backHTML: "Back")
    let backend = MockRustBackend(cards: [card])
    let session = try await ReviewSession(
        backend: backend,
        collectionURL: URL(fileURLWithPath: "/tmp/collection.anki2")
    )

    let next = try await session.nextCard()
    #expect(next == card)

    let outcome = try await session.answer(card, with: .good)
    #expect(outcome == ReviewOutcome(cardID: 42, rating: .good, nextReviewDate: Date(timeIntervalSince1970: 0)))

    let remaining = try await session.nextCard()
    #expect(remaining == nil)
}
