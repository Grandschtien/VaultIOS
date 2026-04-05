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
                drafts: [validDraft()],
                isPrimaryEnabled: true
            )
        )

        XCTAssertTrue(sut.viewModel.primaryButton.isLoading)
        XCTAssertFalse(sut.viewModel.primaryButton.isEnabled)
        XCTAssertFalse(sut.viewModel.isScrollEnabled)
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
                drafts: [validDraft(), validDraft(currencyCode: "EUR")],
                currentPage: 0,
                primaryAction: .next,
                isPrimaryEnabled: true,
                isSkipVisible: true
            )
        )

        XCTAssertEqual(sut.viewModel.forms.count, 2)
        XCTAssertEqual(sut.viewModel.primaryButton.title, L10n.next)
        XCTAssertEqual(sut.viewModel.skipButton?.title, L10n.expenseManualEntrySkip)
        XCTAssertEqual(sut.viewModel.pageControl?.pageCount, 2)
        XCTAssertEqual(sut.viewModel.pageControl?.currentPage, 0)
    }

    func testPresentFetchedDataBuildsAmountPlaceholderFromDraftCurrency() {
        let sut = ExpenseManualEntryPresenter(
            viewModel: ExpenseManualEntryViewModel(),
            colorProvider: CategoryColorProvider()
        )

        sut.presentFetchedData(
            ExpenseManualEntryFetchData(
                drafts: [validDraft(currencyCode: "EUR")]
            )
        )

        XCTAssertEqual(sut.viewModel.forms.first?.amountInput.placeholder, "€0.00")
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
