import XCTest
import UIKit
@testable import Vylok

@MainActor
final class ExpesiesListPresenterTests: XCTestCase {
    private var formatter: MainValueFormattingMock!
    private var colorProvider: CategoryColorProvidingMock!
    private var sut: ExpesiesListPresenter!

    override func setUp() {
        super.setUp()
        formatter = MainValueFormattingMock()
        formatter.formatAmountCurrencyCodeClosure = { "amount-\($0)-\($1)" }
        formatter.formatExpenseAmountCurrencyCodeClosure = { "-amount-\($0)-\($1)" }
        formatter.formatSummaryPeriodClosure = { "from-\(Int($0.timeIntervalSince1970))" }
        formatter.formatSummaryChangeClosure = { "summary-\($0)" }
        formatter.formatSectionDateNowClosure = { date, _ in "section-\(Int(date.timeIntervalSince1970))" }
        formatter.formatExpenseTimeNowClosure = { date, _ in "time-\(Int(date.timeIntervalSince1970))" }
        colorProvider = CategoryColorProvidingMock()
        colorProvider.colorForReturnValue = .systemTeal
        colorProvider.summaryColorForReturnValue = .systemTeal
        colorProvider.accentColorForReturnValue = .systemMint
        colorProvider.normalizedHexFromClosure = { $0 }
        colorProvider.hexStringFromReturnValue = "#008080"
        sut = ExpesiesListPresenter(
            viewModel: .init(),
            formatter: formatter,
            colorProvider: colorProvider
        )
    }

    override func tearDown() {
        formatter = nil
        colorProvider = nil
        sut = nil
        super.tearDown()
    }
}

extension ExpesiesListPresenterTests {
    func testPresentFetchedDataLoadingBuildsSkeletonRows() {
        sut.presentFetchedData(
            .init(loadingState: .loading)
        )

        XCTAssertEqual(sut.viewModel.navigationTitle.text, L10n.mainOverviewRecentExpenses)

        guard case let .loading(sections) = sut.viewModel.state else {
            return XCTFail("Expected loading state")
        }

        XCTAssertEqual(sections.count, 1)
        XCTAssertEqual(sections[0].items.count, 6)
    }
}

extension ExpesiesListPresenterTests {
    func testPresentFetchedDataLoadedMapsSectionsAndPaginationState() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        sut.presentFetchedData(
            .init(
                loadingState: .loaded,
                categories: [
                    .init(
                        id: "cat-1",
                        name: "Food",
                        icon: "🍴",
                        color: "light_orange"
                    )
                ],
                expenseGroups: [
                    .init(
                        date: now,
                        expenses: [
                            .init(
                                id: "expense-1",
                                title: "Coffee",
                                description: "Morning",
                                amount: 4.5,
                                currency: "USD",
                                category: "cat-1",
                                timeOfAdd: now
                            )
                        ]
                    )
                ],
                isLoadingNextPage: true,
                hasMore: true
            )
        )

        guard case let .loaded(content) = sut.viewModel.state else {
            return XCTFail("Expected loaded state")
        }

        XCTAssertEqual(content.sections.count, 1)
        XCTAssertEqual(content.sections[0].title.text, "section-1700000000")
        XCTAssertEqual(content.sections[0].items.count, 1)
        XCTAssertEqual(content.sections[0].items[0].iconText, "🍴")
        XCTAssertEqual(content.sections[0].items[0].amount.text, "-amount-4.5-USD")
        XCTAssertEqual(content.sections[0].items[0].subtitle.text, "time-1700000000")
        XCTAssertEqual(content.sections[0].items[0].iconBackgroundColor, .systemTeal)
        XCTAssertTrue(content.isLoadingNextPage)
        XCTAssertTrue(content.hasMore)
        XCTAssertNotEqual(sut.viewModel.loadNextPageCommand, .nope)
    }
}

extension ExpesiesListPresenterTests {
    func testPresentFetchedDataLoadedEmptyShowsEmptyMessage() {
        sut.presentFetchedData(
            .init(
                loadingState: .loaded,
                expenseGroups: []
            )
        )

        guard case let .empty(text) = sut.viewModel.state else {
            return XCTFail("Expected empty state")
        }

        XCTAssertEqual(text, L10n.mainOverviewEmptyExpenses)
    }
}

extension ExpesiesListPresenterTests {
    func testPresentFetchedDataFailedShowsErrorViewModel() {
        sut.presentFetchedData(
            .init(
                loadingState: .failed(.undelinedError(description: "failed"))
            )
        )

        guard case let .error(errorViewModel) = sut.viewModel.state else {
            return XCTFail("Expected error state")
        }

        XCTAssertNotEqual(errorViewModel.tapCommand, .nope)
    }
}
