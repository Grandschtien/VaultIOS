import XCTest
@testable import Vault

final class ExpenseManualEntryRequestBuilderTests: XCTestCase {
    private let sut = ExpenseManualEntryRequestBuilder()

    func testMakeRequestBuildsTrimmedExpense() {
        let timeOfAdd = Date(timeIntervalSince1970: 1_735_725_600)

        let request = sut.makeRequest(
            amountText: "45,50",
            titleText: "  Lunch at Nando's  ",
            descriptionText: "  Quick lunch  ",
            selectedCategory: .init(
                id: "food",
                name: "Food",
                icon: "🍔",
                color: "green"
            ),
            currencyCode: " eur ",
            timeOfAdd: timeOfAdd
        )

        XCTAssertEqual(request?.expenses.count, 1)
        XCTAssertEqual(request?.expenses.first?.title, "Lunch at Nando's")
        XCTAssertEqual(request?.expenses.first?.description, "Quick lunch")
        XCTAssertEqual(request?.expenses.first?.amount, 45.5)
        XCTAssertEqual(request?.expenses.first?.currency, "EUR")
        XCTAssertEqual(request?.expenses.first?.category, "food")
        XCTAssertEqual(request?.expenses.first?.timeOfAdd, timeOfAdd)
    }

    func testMakeRequestRejectsBlankTitle() {
        let request = sut.makeRequest(
            amountText: "45.00",
            titleText: "   ",
            descriptionText: "",
            selectedCategory: .init(
                id: "food",
                name: "Food",
                icon: "🍔",
                color: "green"
            ),
            currencyCode: "USD",
            timeOfAdd: Date()
        )

        XCTAssertNil(request)
    }

    func testMakeRequestRejectsMissingCategory() {
        let request = sut.makeRequest(
            amountText: "45.00",
            titleText: "Lunch",
            descriptionText: "",
            selectedCategory: nil,
            currencyCode: "USD",
            timeOfAdd: Date()
        )

        XCTAssertNil(request)
    }

    func testMakeRequestRejectsInvalidAmount() {
        let request = sut.makeRequest(
            amountText: "0",
            titleText: "Lunch",
            descriptionText: "",
            selectedCategory: .init(
                id: "food",
                name: "Food",
                icon: "🍔",
                color: "green"
            ),
            currencyCode: "USD",
            timeOfAdd: Date()
        )

        XCTAssertNil(request)
    }
}
