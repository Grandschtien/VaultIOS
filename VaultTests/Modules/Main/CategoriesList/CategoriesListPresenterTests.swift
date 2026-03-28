import XCTest
@testable import Vault

@MainActor
final class CategoriesListPresenterTests: XCTestCase {
    private var formatter: MainValueFormatterStub!
    private var sut: CategoriesListPresenter!

    override func setUp() {
        super.setUp()
        formatter = MainValueFormatterStub()
        sut = CategoriesListPresenter(
            viewModel: .init(),
            formatter: formatter
        )
    }

    override func tearDown() {
        formatter = nil
        sut = nil
        super.tearDown()
    }
}

extension CategoriesListPresenterTests {
    func testPresentFetchedDataLoadingBuildsTenSkeletonItems() {
        sut.presentFetchedData(
            CategoriesListFetchData(
                loadingState: .loading
            )
        )

        guard case let .loading(items) = sut.viewModel.state else {
            return XCTFail("Expected loading state")
        }

        XCTAssertEqual(items.count, 10)
        XCTAssertTrue(items.allSatisfy(\.isLoading))
    }
}

extension CategoriesListPresenterTests {
    func testPresentFetchedDataLoadedMapsItems() {
        sut.presentFetchedData(
            CategoriesListFetchData(
                loadingState: .loaded,
                categories: [
                    .init(
                        id: "cat-1",
                        name: "Food",
                        icon: "🍴",
                        color: "light_orange",
                        amount: 12.5,
                        currency: "USD"
                    )
                ]
            )
        )

        guard case let .loaded(items) = sut.viewModel.state else {
            return XCTFail("Expected loaded state")
        }

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].title.text, "Food")
        XCTAssertEqual(items[0].amount.text, "amount-12.5-USD")
        XCTAssertFalse(items[0].isAmountHidden)
    }
}

extension CategoriesListPresenterTests {
    func testPresentFetchedDataLoadedEmptyBuildsEmptyState() {
        sut.presentFetchedData(
            CategoriesListFetchData(
                loadingState: .loaded,
                categories: []
            )
        )

        guard case let .empty(text) = sut.viewModel.state else {
            return XCTFail("Expected empty state")
        }

        XCTAssertEqual(text, L10n.mainOverviewEmptyCategories)
    }
}

extension CategoriesListPresenterTests {
    func testPresentFetchedDataFailureBuildsErrorState() {
        sut.presentFetchedData(
            CategoriesListFetchData(
                loadingState: .failed(.undelinedError(description: "Failed"))
            )
        )

        guard case .error = sut.viewModel.state else {
            return XCTFail("Expected error state")
        }
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
