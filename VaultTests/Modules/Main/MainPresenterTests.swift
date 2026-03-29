import XCTest
import UIKit
@testable import Vault

@MainActor
final class MainPresenterTests: XCTestCase {
    private var formatter: MainValueFormatterStub!
    private var colorProvider: CategoryColorProviderStub!
    private var sut: MainPresenter!

    override func setUp() {
        super.setUp()
        formatter = MainValueFormatterStub()
        colorProvider = CategoryColorProviderStub()
        sut = MainPresenter(
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
        XCTAssertEqual(sut.viewModel.summarySection.amount.text, L10n.mainOverviewLoading)
        XCTAssertTrue(sut.viewModel.categoriesSection.isLoading)
        XCTAssertTrue(sut.viewModel.expensesSection.isLoading)
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

        XCTAssertEqual(sut.viewModel.summarySection.amount.text, "amount-2450.8-USD")
        XCTAssertNil(sut.viewModel.summarySection.trend)

        XCTAssertEqual(sut.viewModel.categoriesSection.items.count, 1)
        XCTAssertEqual(sut.viewModel.categoriesSection.items[0].title.text, "Food")
        XCTAssertFalse(sut.viewModel.categoriesSection.items[0].isAmountHidden)
        XCTAssertEqual(sut.viewModel.categoriesSection.items[0].iconBackgroundColor, .systemTeal)
        XCTAssertNotEqual(sut.viewModel.categoriesSection.items[0].tapCommand, .nope)
        XCTAssertNotEqual(sut.viewModel.categoriesSection.seeAllCommand, .nope)

        XCTAssertEqual(sut.viewModel.expensesSection.sections.count, 1)
        XCTAssertEqual(sut.viewModel.expensesSection.sections[0].title.text, "section-1000")
        XCTAssertEqual(sut.viewModel.expensesSection.sections[0].items.count, 1)
        XCTAssertEqual(sut.viewModel.expensesSection.sections[0].items[0].amount.text, "-amount-4.5-USD")
        XCTAssertEqual(sut.viewModel.expensesSection.sections[0].items[0].subtitle.text, "time-1000")
        XCTAssertEqual(sut.viewModel.expensesSection.sections[0].items[0].iconBackgroundColor, .systemTeal)
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
        XCTAssertNotNil(sut.viewModel.expensesSection.errorViewModel)
        XCTAssertTrue(sut.viewModel.categoriesSection.items.isEmpty)
        XCTAssertTrue(sut.viewModel.expensesSection.sections.isEmpty)
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
    func summaryColor(for value: String) -> UIColor {
        .systemTeal
    }

    func accentColor(for value: String) -> UIColor {
        .systemMint
    }
}
