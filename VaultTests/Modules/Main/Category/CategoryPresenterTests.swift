import XCTest
import UIKit
@testable import Vault

@MainActor
final class CategoryPresenterTests: XCTestCase {
    private var formatter: MainValueFormatterStub!
    private var colorProvider: CategoryColorProviderStub!
    private var sut: CategoryPresenter!

    override func setUp() {
        super.setUp()
        formatter = MainValueFormatterStub()
        colorProvider = CategoryColorProviderStub()
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
    func testPresentFetchedDataLoadingBuildsSkeletonContent() {
        sut.presentFetchedData(
            .init(
                navigationTitle: "Food",
                loadingState: .loading
            )
        )

        XCTAssertEqual(sut.viewModel.navigationTitle.text, "Food")
        XCTAssertEqual(sut.viewModel.editButtonTitle, L10n.categoryEditButton)
        XCTAssertNotEqual(sut.viewModel.editButtonCommand, .nope)

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

        sut.presentFetchedData(
            .init(
                navigationTitle: "Food",
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
        XCTAssertEqual(content.summary.amount.text, "amount-321.0-USD")
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

private final class MainValueFormatterStub: MainValueFormatting, @unchecked Sendable {
    func formatAmount(_ amount: Double, currencyCode: String) -> String {
        "amount-\(amount)-\(currencyCode)"
    }

    func formatExpenseAmount(_ amount: Double, currencyCode: String) -> String {
        "-amount-\(amount)-\(currencyCode)"
    }

    func formatSummaryPeriod(_ date: Date) -> String {
        "from-\(Int(date.timeIntervalSince1970))"
    }

    func formatSummaryChange(_ percent: Double) -> String {
        "summary-\(percent)"
    }

    func formatSectionDate(_ date: Date, now: Date) -> String {
        "section-\(Int(date.timeIntervalSince1970))"
    }

    func formatExpenseTime(_ date: Date, now: Date) -> String {
        "time-\(Int(date.timeIntervalSince1970))"
    }
}

private final class CategoryColorProviderStub: CategoryColorProviding, @unchecked Sendable {
    func summaryColor(for value: String) -> UIColor {
        .systemTeal
    }

    func accentColor(for value: String) -> UIColor {
        .systemMint
    }
}
