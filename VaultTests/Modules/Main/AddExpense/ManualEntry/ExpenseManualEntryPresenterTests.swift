import XCTest
@testable import Vault

@MainActor
final class ExpenseManualEntryPresenterTests: XCTestCase {
    func testPresentFetchedDataShowsLoadingOnPrimaryButton() {
        let sut = ExpenseManualEntryPresenter(
            viewModel: ExpenseManualEntryViewModel(),
            colorProvider: CategoryColorProvider()
        )

        sut.presentFetchedData(
            ExpenseManualEntryFetchData(
                loadingState: .loading,
                currentDraft: validDraft(),
                isPrimaryEnabled: true
            )
        )

        XCTAssertTrue(sut.viewModel.primaryButton.isLoading)
        XCTAssertFalse(sut.viewModel.primaryButton.isEnabled)
        XCTAssertFalse(sut.viewModel.currentDraft?.amountInput.isEnabled ?? true)
        XCTAssertFalse(sut.viewModel.header.isCloseEnabled)
    }
}

extension ExpenseManualEntryPresenterTests {
    func testPresentFetchedDataBuildsPagedMultiDraftState() {
        let sut = ExpenseManualEntryPresenter(
            viewModel: ExpenseManualEntryViewModel(),
            colorProvider: CategoryColorProvider()
        )

        sut.presentFetchedData(
            ExpenseManualEntryFetchData(
                currentDraft: validDraft(),
                primaryAction: .next,
                isPrimaryEnabled: true,
                isSkipVisible: true
            )
        )

        XCTAssertEqual(sut.viewModel.currentDraft?.titleField.text, "Lunch")
        XCTAssertEqual(sut.viewModel.primaryButton.title, L10n.next)
        XCTAssertEqual(sut.viewModel.skipButton?.title, L10n.expenseManualEntrySkip)
        XCTAssertNotNil(sut.viewModel.currentDraft)
    }

    func testPresentFetchedDataBuildsAmountPlaceholderFromDraftCurrency() {
        let sut = ExpenseManualEntryPresenter(
            viewModel: ExpenseManualEntryViewModel(),
            colorProvider: CategoryColorProvider()
        )

        sut.presentFetchedData(
            ExpenseManualEntryFetchData(
                currentDraft: validDraft(currencyCode: "EUR")
            )
        )

        XCTAssertEqual(sut.viewModel.currentDraft?.amountInput.currencyLabel.text, "€")
    }
}

private extension ExpenseManualEntryPresenterTests {
    func validDraft(currencyCode: String = "USD") -> ExpenseEditableDraft {
        ExpenseEditableDraft(
            amountText: "45.00",
            titleText: "Lunch",
            descriptionText: "",
            selectedCategory: .init(
                id: "food",
                name: "Food",
                icon: "🍔",
                color: "green"
            ),
            currencyCode: currencyCode
        )
    }
}
