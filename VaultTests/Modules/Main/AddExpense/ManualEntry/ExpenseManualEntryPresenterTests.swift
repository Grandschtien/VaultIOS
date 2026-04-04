import XCTest
@testable import Vault

@MainActor
final class ExpenseManualEntryPresenterTests: XCTestCase {
    func testPresentFetchedDataShowsLoadingOnConfirmButton() {
        let sut = ExpenseManualEntryPresenter(
            viewModel: ExpenseManualEntryViewModel(),
            colorProvider: CategoryColorProvider()
        )

        sut.presentFetchedData(
            ExpenseManualEntryFetchData(
                loadingState: .loading,
                isConfirmEnabled: true,
                amountText: "45.00",
                titleText: "Lunch",
                selectedCategory: .init(
                    id: "food",
                    name: "Food",
                    icon: "🍔",
                    color: "green"
                )
            )
        )

        XCTAssertTrue(sut.viewModel.confirmButton.isLoading)
        XCTAssertFalse(sut.viewModel.confirmButton.isEnabled)
    }

    func testPresentFetchedDataDisablesConfirmForInvalidDraft() {
        let sut = ExpenseManualEntryPresenter(
            viewModel: ExpenseManualEntryViewModel(),
            colorProvider: CategoryColorProvider()
        )

        sut.presentFetchedData(
            ExpenseManualEntryFetchData(
                loadingState: .idle,
                isConfirmEnabled: false
            )
        )

        XCTAssertFalse(sut.viewModel.confirmButton.isLoading)
        XCTAssertFalse(sut.viewModel.confirmButton.isEnabled)
    }

    func testPresentFetchedDataBuildsAmountPlaceholderFromCurrencyCode() {
        let sut = ExpenseManualEntryPresenter(
            viewModel: ExpenseManualEntryViewModel(),
            colorProvider: CategoryColorProvider()
        )

        sut.presentFetchedData(
            ExpenseManualEntryFetchData(
                currencyCode: "EUR"
            )
        )

        XCTAssertEqual(sut.viewModel.amountInput.placeholder, "€0.00")
    }
}
