import XCTest
@testable import Vault

final class ExpenseAIParsedDraftMapperTests: XCTestCase {
    private let sut = ExpenseAIParsedDraftMapper()

    func testMakeDraftsUsesParsedCurrencyAndDirectCategoryMatch() {
        let drafts = sut.makeDrafts(
            from: [
                .init(
                    title: "Coffee",
                    amount: 5,
                    currency: "EUR",
                    category: "Food",
                    suggestedCategory: nil,
                    confidence: 0.9
                )
            ],
            categories: [
                .init(
                    id: "food",
                    name: "Food",
                    icon: "🍔",
                    color: "green",
                    amount: 0,
                    currency: "USD"
                )
            ],
            fallbackCurrencyCode: "USD"
        )

        XCTAssertEqual(drafts.count, 1)
        XCTAssertEqual(drafts.first?.currencyCode, "EUR")
        XCTAssertEqual(drafts.first?.selectedCategory?.id, "food")
        XCTAssertEqual(drafts.first?.descriptionText, "")
    }
}

extension ExpenseAIParsedDraftMapperTests {
    func testMakeDraftsFallsBackToSuggestedCategoryWhenUnmapped() {
        let drafts = sut.makeDrafts(
            from: [
                .init(
                    title: "Taxi",
                    amount: 12,
                    currency: "",
                    category: "UNMAPPED",
                    suggestedCategory: "Transport",
                    confidence: 0.9
                )
            ],
            categories: [
                .init(
                    id: "transport",
                    name: "Transport",
                    icon: "🚕",
                    color: "blue",
                    amount: 0,
                    currency: "USD"
                )
            ],
            fallbackCurrencyCode: "KZT"
        )

        XCTAssertEqual(drafts.first?.currencyCode, "KZT")
        XCTAssertEqual(drafts.first?.selectedCategory?.id, "transport")
    }

    func testMakeDraftsLeavesCategoryEmptyWhenUnmappedNameDoesNotMatch() {
        let drafts = sut.makeDrafts(
            from: [
                .init(
                    title: "Taxi",
                    amount: 12,
                    currency: "",
                    category: "UNMAPPED",
                    suggestedCategory: "Travel",
                    confidence: 0.9
                )
            ],
            categories: [],
            fallbackCurrencyCode: "USD"
        )

        XCTAssertNil(drafts.first?.selectedCategory)
    }
}
