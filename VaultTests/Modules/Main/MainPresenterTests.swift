import XCTest
import UIKit
@testable import Vault

@MainActor
final class MainPresenterTests: XCTestCase {
    private var formatter: MainValueFormatterStub!
    private var colorProvider: CategoryColorProviderStub!
    private var summaryPeriodProvider: MainSummaryPeriodProviderStub!
    private var sut: MainPresenter!

    override func setUp() {
        super.setUp()
        formatter = MainValueFormatterStub()
        colorProvider = CategoryColorProviderStub()
        summaryPeriodProvider = MainSummaryPeriodProviderStub(
            period: .init(
                from: Date(timeIntervalSince1970: 1),
                to: Date(timeIntervalSince1970: 2)
            )
        )
        sut = MainPresenter(
            viewModel: .init(),
            formatter: formatter,
            colorProvider: colorProvider,
            summaryPeriodProvider: summaryPeriodProvider
        )
    }

    override func tearDown() {
        formatter = nil
        colorProvider = nil
        summaryPeriodProvider = nil
        sut = nil
        super.tearDown()
    }
}

extension MainPresenterTests {
    func testPresentFetchedDataLoadingBuildsLoadingState() {
        sut.presentFetchedData(
            MainFetchData(
                summaryState: .loading,
                categoriesState: .loading,
                expensesState: .loading
            )
        )

        XCTAssertEqual(sut.viewModel.navigationTitle.text, L10n.mainOverviewTitle)
        XCTAssertEqual(sut.viewModel.summarySection.periodDescription.text, "from-1")
        XCTAssertEqual(sut.viewModel.summarySection.amount.text, L10n.mainOverviewLoading)
        XCTAssertTrue(sut.viewModel.categoriesSection.isLoading)
        XCTAssertTrue(isExpensesState(sut.viewModel.expensesSection.state, .loading))
    }
}

extension MainPresenterTests {
    func testPresentFetchedDataLoadedMapsSectionsAndCommands() {
        let today = Date(timeIntervalSince1970: 1000)

        sut.presentFetchedData(
            MainFetchData(
                summaryState: .loaded,
                categoriesState: .loaded,
                expensesState: .loaded,
                summary: .init(totalAmount: 2450.8, currency: "USD", changePercent: 12),
                categories: [
                    .init(
                        id: "cat-1",
                        name: "Food",
                        icon: "🍴",
                        color: "light_orange",
                        amount: 450.2,
                        currency: "USD"
                    )
                ],
                expenseGroups: [
                    .init(
                        date: today,
                        expenses: [
                            .init(
                                id: "exp-1",
                                title: "Coffee",
                                description: "Morning",
                                amount: 4.5,
                                currency: "USD",
                                category: "cat-1",
                                timeOfAdd: today
                            )
                        ]
                    )
                ]
            )
        )

        XCTAssertEqual(sut.viewModel.summarySection.periodDescription.text, "from-1")
        XCTAssertEqual(sut.viewModel.summarySection.amount.text, "amount-2450.8-USD")
        XCTAssertNil(sut.viewModel.summarySection.trend)

        XCTAssertEqual(sut.viewModel.categoriesSection.items.count, 1)
        XCTAssertEqual(sut.viewModel.categoriesSection.items[0].title.text, "Food")
        XCTAssertFalse(sut.viewModel.categoriesSection.items[0].isAmountHidden)
        XCTAssertEqual(sut.viewModel.categoriesSection.items[0].iconBackgroundColor, .systemTeal)
        XCTAssertNotEqual(sut.viewModel.categoriesSection.items[0].tapCommand, .nope)
        XCTAssertNotEqual(sut.viewModel.categoriesSection.seeAllCommand, .nope)

        let expensesSections: [MainExpensesSectionView.SectionViewModel]
        if case let .loaded(content) = sut.viewModel.expensesSection.state {
            expensesSections = content
        } else {
            XCTFail("Expected loaded expenses state")
            return
        }

        XCTAssertEqual(expensesSections.count, 1)
        XCTAssertEqual(expensesSections[0].title.text, "section-1000")
        XCTAssertEqual(expensesSections[0].items.count, 1)
        XCTAssertEqual(expensesSections[0].items[0].amount.text, "-amount-4.5-USD")
        XCTAssertEqual(expensesSections[0].items[0].subtitle.text, "time-1000")
        XCTAssertEqual(expensesSections[0].items[0].iconBackgroundColor, .systemTeal)
        XCTAssertNotEqual(sut.viewModel.expensesSection.seeAllCommand, .nope)
    }
}

extension MainPresenterTests {
    func testPresentFetchedDataFailureShowsSectionErrorViewModels() {
        sut.presentFetchedData(
            MainFetchData(
                summaryState: .failed(.undelinedError(description: "summary failed")),
                categoriesState: .failed(.undelinedError(description: "categories failed")),
                expensesState: .failed(.undelinedError(description: "expenses failed"))
            )
        )

        XCTAssertNotNil(sut.viewModel.summarySection.errorViewModel)
        XCTAssertNotNil(sut.viewModel.categoriesSection.errorViewModel)
        XCTAssertTrue(isExpensesState(sut.viewModel.expensesSection.state, .error))
        XCTAssertTrue(sut.viewModel.categoriesSection.items.isEmpty)
    }
}

extension MainPresenterTests {
    func testPresentFetchedDataWithBlockingErrorBuildsBlockingViewModel() {
        sut.presentFetchedData(
            MainFetchData(
                blockingErrorDescription: L10n.mainOverviewError,
                summaryState: .idle,
                categoriesState: .idle,
                expensesState: .idle
            )
        )

        XCTAssertTrue(sut.viewModel.isInteractionBlocked)
        XCTAssertEqual(sut.viewModel.blockingErrorViewModel?.title.text, L10n.mainOverviewError)
        XCTAssertEqual(sut.viewModel.blockingErrorViewModel?.subtitle.text, L10n.mainOverviewError)
        XCTAssertNotEqual(sut.viewModel.blockingErrorViewModel?.retryButton.tapCommand, .nope)
    }
}

extension MainPresenterTests {
    func testPresentFetchedDataWithoutBlockingErrorHidesBlockingViewModel() {
        sut.presentFetchedData(
            MainFetchData(
                summaryState: .loaded,
                categoriesState: .loaded,
                expensesState: .loaded
            )
        )

        XCTAssertFalse(sut.viewModel.isInteractionBlocked)
        XCTAssertNil(sut.viewModel.blockingErrorViewModel)
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
        "trend-\(percent)"
    }

    func formatSectionDate(_ date: Date, now: Date) -> String {
        "section-\(Int(date.timeIntervalSince1970))"
    }

    func formatExpenseTime(_ date: Date, now: Date) -> String {
        "time-\(Int(date.timeIntervalSince1970))"
    }
}

private final class CategoryColorProviderStub: CategoryColorProviding, @unchecked Sendable {
    func color(for value: String) -> UIColor {
        .systemTeal
    }

    func summaryColor(for value: String) -> UIColor {
        .systemTeal
    }

    func accentColor(for value: String) -> UIColor {
        .systemMint
    }

    func normalizedHex(from value: String) -> String? {
        value
    }

    func hexString(from color: UIColor) -> String? {
        "#008080"
    }
}

private final class MainSummaryPeriodProviderStub: MainSummaryPeriodProviding, @unchecked Sendable {
    private let period: MainSummaryPeriod

    init(period: MainSummaryPeriod) {
        self.period = period
    }

    func currentMonthPeriod() -> MainSummaryPeriod {
        period
    }
}

private extension MainPresenterTests {
    enum MainExpensesStateCase {
        case loading
        case empty
        case loaded
        case error
    }

    func isExpensesState(
        _ state: MainExpensesSectionView.State,
        _ expected: MainExpensesStateCase
    ) -> Bool {
        switch (state, expected) {
        case (.loading, .loading), (.empty, .empty), (.loaded, .loaded), (.error, .error):
            return true
        default:
            return false
        }
    }
}
