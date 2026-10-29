import XCTest
import UIKit
@testable import Vylok

@MainActor
final class CategoryPresenterTests: XCTestCase {
    private var formatter: MainValueFormattingMock!
    private var colorProvider: CategoryColorProvidingMock!
    private var sut: CategoryPresenter!

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
        sut = CategoryPresenter(
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

extension CategoryPresenterTests {
    func testPresentFetchedDataBuildsEditButtonWhenCategoryCanBeEdited() {
        sut.presentFetchedData(
            .init(
                navigationTitle: "Food",
                loadingState: .loaded,
                canEditCategory: true
            )
        )

        XCTAssertEqual(sut.viewModel.editButton?.content, .edit)
    }

    func testPresentFetchedDataHidesEditButtonWhenCategoryCannotBeEdited() {
        sut.presentFetchedData(
            .init(
                navigationTitle: "Other",
                loadingState: .loaded,
                canEditCategory: false
            )
        )

        XCTAssertNil(sut.viewModel.editButton)
    }
}

extension CategoryPresenterTests {
    func testPresentFetchedDataLoadingWithCachedSummaryBuildsRealSummaryAndSkeletonExpenses() {
        let fromDate = Date(timeIntervalSince1970: 10)

        sut.presentFetchedData(
            .init(
                navigationTitle: "Food",
                fromDate: fromDate,
                loadingState: .loading,
                category: .init(
                    id: "cat-1",
                    name: "Food",
                    icon: "🍴",
                    color: "light_orange",
                    amount: 321,
                    currency: "USD"
                )
            )
        )

        let content = sut.viewModel.content
        guard case let .loading(sections) = content.state else {
            return XCTFail("Expected loading state")
        }

        XCTAssertFalse(content.summary.isLoading)
        XCTAssertEqual(content.summary.amount.text, "amount-321.0-USD")
        XCTAssertEqual(sections.count, 1)
        XCTAssertTrue(sections[0].items.allSatisfy(\.isLoading))
    }

    func testPresentFetchedDataLoadingBuildsSkeletonContent() {
        let fromDate = Date(timeIntervalSince1970: 10)

        sut.presentFetchedData(
            .init(
                navigationTitle: "Food",
                fromDate: fromDate,
                loadingState: .loading
            )
        )

        XCTAssertEqual(sut.viewModel.navigationTitle.text, "Food")

        let content = sut.viewModel.content
        guard case let .loading(sections) = content.state else {
            return XCTFail("Expected loading state")
        }

        XCTAssertTrue(content.summary.isLoading)
        XCTAssertEqual(sections.count, 1)
        XCTAssertEqual(sections[0].items.count, 8)
        XCTAssertTrue(sections[0].items.allSatisfy(\.isLoading))
    }
}

extension CategoryPresenterTests {
    func testPresentFetchedDataLoadedMapsSummaryAndDeleteState() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let fromDate = Date(timeIntervalSince1970: 1_699_000_000)

        sut.presentFetchedData(
            .init(
                navigationTitle: "Food",
                fromDate: fromDate,
                loadingState: .loaded,
                category: .init(
                    id: "cat-1",
                    name: "Food",
                    icon: "🍴",
                    color: "light_orange",
                    amount: 321,
                    currency: "USD"
                ),
                expenseGroups: [
                    .init(
                        date: now,
                        expenses: [
                            .init(
                                id: "exp-1",
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
                deletingExpenseIDs: ["exp-1"],
                isLoadingNextPage: true,
                hasMore: true
            )
        )

        let content = sut.viewModel.content
        guard case let .loaded(sections) = content.state else {
            return XCTFail("Expected loaded state")
        }

        XCTAssertEqual(content.summary.iconText, "🍴")
        XCTAssertEqual(content.summary.title.text, L10n.mainOverviewTotalSpending)
        XCTAssertEqual(content.summary.amount.text, "amount-321.0-USD")
        XCTAssertEqual(content.summary.note.text, "from-1699000000")
        XCTAssertEqual(sections.count, 1)
        XCTAssertEqual(sections[0].title.text, "section-1700000000")
        XCTAssertEqual(sections[0].items.count, 1)
        XCTAssertEqual(sections[0].items[0].amount.text, "-amount-4.5-USD")
        XCTAssertEqual(sections[0].items[0].subtitle.text, "time-1700000000")
        XCTAssertEqual(sections[0].items[0].deleteLabel.text, L10n.categoryDelete)
        XCTAssertEqual(sections[0].items[0].deleteState, .deleting)
        XCTAssertNotEqual(sections[0].items[0].deleteCommand, .nope)
        XCTAssertTrue(content.isLoadingNextPage)
        XCTAssertTrue(content.hasMore)
    }
}

extension CategoryPresenterTests {
    func testPresentFetchedDataLoadedEmptyBuildsEmptyText() {
        sut.presentFetchedData(
            .init(
                navigationTitle: "Food",
                loadingState: .loaded,
                category: .init(
                    id: "cat-1",
                    name: "Food",
                    icon: "🍴",
                    color: "light_orange",
                    amount: 0,
                    currency: "USD"
                ),
                expenseGroups: []
            )
        )

        guard case let .empty(text) = sut.viewModel.content.state else {
            return XCTFail("Expected empty state")
        }

        XCTAssertEqual(text, L10n.mainOverviewEmptyExpenses)
    }
}

extension CategoryPresenterTests {
    func testPresentFetchedDataFailureBuildsErrorState() {
        sut.presentFetchedData(
            .init(
                navigationTitle: "Food",
                loadingState: .failed(.undelinedError(description: "error"))
            )
        )

        guard case let .failed(errorViewModel) = sut.viewModel.content.state else {
            return XCTFail("Expected failed state")
        }

        XCTAssertNotEqual(errorViewModel.tapCommand, .nope)
    }
}
