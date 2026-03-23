import XCTest
@testable import Vault

@MainActor
final class MainPresenterTests: XCTestCase {
    private var formatter: MainValueFormatterStub!
    private var sut: MainPresenter!

    override func setUp() {
        super.setUp()
        formatter = MainValueFormatterStub()
        sut = MainPresenter(viewModel: .init(), formatter: formatter)
    }

    override func tearDown() {
        formatter = nil
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
        XCTAssertEqual(sut.viewModel.summarySection.trend.text, "trend-12.0")

        XCTAssertEqual(sut.viewModel.categoriesSection.items.count, 1)
        XCTAssertEqual(sut.viewModel.categoriesSection.items[0].title.text, "Food")
        XCTAssertNotEqual(sut.viewModel.categoriesSection.seeAllCommand, .nope)

        XCTAssertEqual(sut.viewModel.expensesSection.sections.count, 1)
        XCTAssertEqual(sut.viewModel.expensesSection.sections[0].title.text, "section-1000")
        XCTAssertEqual(sut.viewModel.expensesSection.sections[0].items.count, 1)
        XCTAssertEqual(sut.viewModel.expensesSection.sections[0].items[0].amount.text, "-amount-4.5-USD")
        XCTAssertEqual(sut.viewModel.expensesSection.sections[0].items[0].subtitle.text, "time-1000")
        XCTAssertNotEqual(sut.viewModel.expensesSection.seeAllCommand, .nope)
    }
}

extension MainPresenterTests {
    func testPresentFetchedDataFailureShowsErrorText() {
        sut.presentFetchedData(
            MainFetchData(
                summaryState: .failed(StubError(message: "summary failed")),
                categoriesState: .failed(StubError(message: "categories failed")),
                expensesState: .failed(StubError(message: "expenses failed"))
            )
        )

        XCTAssertEqual(sut.viewModel.summarySection.amount.text, L10n.mainOverviewError)
        XCTAssertEqual(sut.viewModel.summarySection.trend.text, "summary failed")
        XCTAssertEqual(sut.viewModel.categoriesSection.emptyText, "categories failed")
        XCTAssertEqual(sut.viewModel.expensesSection.emptyText, "expenses failed")
    }
}

private final class MainValueFormatterStub: MainValueFormatting, @unchecked Sendable {
    func formatAmount(_ amount: Double, currencyCode: String) -> String {
        "amount-\(amount)-\(currencyCode)"
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

private struct StubError: LocalizedError {
    let message: String

    var errorDescription: String? {
        message
    }
}
