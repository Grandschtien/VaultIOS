import XCTest
import UIKit
@testable import Vylok

@MainActor
final class CategoriesListPresenterTests: XCTestCase {
    private var formatter: MainValueFormattingMock!
    private var colorProvider: CategoryColorProvidingMock!
    private var sut: CategoriesListPresenter!

    override func setUp() {
        super.setUp()
        formatter = MainValueFormattingMock()
        formatter.formatAmountCurrencyCodeClosure = { "amount-\($0)-\($1)" }
        formatter.formatExpenseAmountCurrencyCodeClosure = { "-amount-\($0)-\($1)" }
        formatter.formatSummaryPeriodClosure = { "from-\(Int($0.timeIntervalSince1970))" }
        formatter.formatSummaryChangeClosure = { "trend-\($0)" }
        formatter.formatSectionDateNowClosure = { date, _ in "section-\(Int(date.timeIntervalSince1970))" }
        formatter.formatExpenseTimeNowClosure = { date, _ in "time-\(Int(date.timeIntervalSince1970))" }
        colorProvider = CategoryColorProvidingMock()
        colorProvider.colorForReturnValue = .systemTeal
        colorProvider.summaryColorForReturnValue = .systemTeal
        colorProvider.accentColorForReturnValue = .systemMint
        colorProvider.normalizedHexFromClosure = { $0 }
        colorProvider.hexStringFromReturnValue = "#008080"
        sut = CategoriesListPresenter(
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
        XCTAssertEqual(items[0].iconBackgroundColor, .systemTeal)
        XCTAssertFalse(items[0].isAmountHidden)
        XCTAssertNotEqual(items[0].tapCommand, .nope)
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
