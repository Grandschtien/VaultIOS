import XCTest
@testable import Vault

final class ExpenseManualEntryRequestBuilderTests: XCTestCase {
    private let sut = ExpenseManualEntryRequestBuilder()

    func testMakeRequestBuildsTrimmedExpenses() {
        let timeOfAdd = Date(timeIntervalSince1970: 1_735_725_600)
        let request = sut.makeRequest(
            drafts: [
                .init(
                    amountText: "45,50",
                    titleText: "  Lunch at Nando's  ",
                    descriptionText: "  Quick lunch  ",
                    selectedCategory: .init(
                        id: "food",
                        name: "Food",
                        icon: "🍔",
                        color: "green"
                    ),
                    currencyCode: " eur "
                ),
                .init(
                    amountText: "12",
                    titleText: "Taxi",
                    descriptionText: "",
                    selectedCategory: .init(
                        id: "transport",
                        name: "Transport",
                        icon: "🚕",
                        color: "blue"
                    ),
                    currencyCode: "USD"
                )
            ],
            timeOfAdd: timeOfAdd
        )

        XCTAssertEqual(request?.expenses.count, 2)
        XCTAssertEqual(request?.expenses.first?.title, "Lunch at Nando's")
        XCTAssertEqual(request?.expenses.first?.description, "Quick lunch")
        XCTAssertEqual(request?.expenses.first?.amount, 45.5)
        XCTAssertEqual(request?.expenses.first?.currency, "EUR")
        XCTAssertEqual(request?.expenses.first?.category, "food")
        XCTAssertEqual(request?.expenses.first?.timeOfAdd, timeOfAdd)
        XCTAssertEqual(request?.expenses.last?.currency, "USD")
    }
}

extension ExpenseManualEntryRequestBuilderTests {
    func testIsValidDraftRejectsBlankTitle() {
        XCTAssertFalse(
            sut.isValidDraft(
                .init(
                    amountText: "45.00",
                    titleText: "   ",
                    selectedCategory: .init(
                        id: "food",
                        name: "Food",
                        icon: "🍔",
                        color: "green"
                    ),
                    currencyCode: "USD"
                )
            )
        )
    }

    func testIsValidDraftRejectsMissingCategory() {
        XCTAssertFalse(
            sut.isValidDraft(
                .init(
                    amountText: "45.00",
                    titleText: "Lunch",
                    selectedCategory: nil,
                    currencyCode: "USD"
                )
            )
        )
    }

    func testMakeRequestRejectsInvalidAmount() {
        let request = sut.makeRequest(
            drafts: [
                .init(
                    amountText: "0",
                    titleText: "Lunch",
                    selectedCategory: .init(
                        id: "food",
                        name: "Food",
                        icon: "🍔",
                        color: "green"
                    ),
                    currencyCode: "USD"
                )
            ],
            timeOfAdd: Date()
        )

        XCTAssertNil(request)
    }
}
