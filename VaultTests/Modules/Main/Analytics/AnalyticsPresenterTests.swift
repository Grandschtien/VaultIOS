import XCTest
import UIKit
@testable import Vault

@MainActor
final class AnalyticsPresenterTests: XCTestCase {
    private var formatter: AnalyticsValueFormatterStub!
    private var colorProvider: AnalyticsColorProviderStub!
    private var sut: AnalyticsPresenter!

    override func setUp() {
        super.setUp()
        formatter = AnalyticsValueFormatterStub()
        colorProvider = AnalyticsColorProviderStub()
        sut = AnalyticsPresenter(
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

extension AnalyticsPresenterTests {
    func testPresentFetchedDataLoadingBuildsLoadingState() {
        sut.presentFetchedData(
            .init(
                selectedPeriod: .init(
                    from: Date(timeIntervalSince1970: 1_775_001_600),
                    to: Date(timeIntervalSince1970: 1_775_433_600)
                ),
                loadingState: .loading
            )
        )

        guard case .loading = sut.viewModel.state else {
            return XCTFail("Expected loading state")
        }

        XCTAssertEqual(sut.viewModel.monthBarButton.title, "month")
    }
}

extension AnalyticsPresenterTests {
    func testPresentFetchedDataLockedBuildsLockedState() {
        sut.presentFetchedData(
            .init(
                selectedPeriod: .init(
                    from: Date(timeIntervalSince1970: 1_775_001_600),
                    to: Date(timeIntervalSince1970: 1_775_433_600)
                ),
                isLocked: true
            )
        )

        guard case let .locked(lockedViewModel) = sut.viewModel.state else {
            return XCTFail("Expected locked state")
        }

        XCTAssertEqual(lockedViewModel.button.title, L10n.analyticsSubscribeToSee)
    }
}

extension AnalyticsPresenterTests {
    func testPresentFetchedDataLoadedBuildsChartAndRows() {
        sut.presentFetchedData(
            .init(
                selectedPeriod: .init(
                    from: Date(timeIntervalSince1970: 1_775_001_600),
                    to: Date(timeIntervalSince1970: 1_775_433_600)
                ),
                loadingState: .loaded,
                data: AnalyticsDataModel(
                    monthStart: Date(timeIntervalSince1970: 1_775_001_600),
                    totalAmount: 240,
                    currency: "USD",
                    categories: [
                        makeCategory(id: "food", amount: 100, share: 0.4),
                        makeCategory(id: "shopping", amount: 62.5, share: 0.25),
                        makeCategory(id: "transport", amount: 32.5, share: 0.13),
                        makeCategory(id: "fun", amount: 55, share: 0.22)
                    ]
                )
            )
        )

        guard case let .loaded(content) = sut.viewModel.state else {
            return XCTFail("Expected loaded state")
        }

        XCTAssertEqual(content.periodTitle.text, "01.04.2026 - 06.04.2026")
        XCTAssertEqual(content.totalAmount.text, "amount-240.0-USD")
        XCTAssertEqual(content.chart.legendItems.map(\.title), ["food", "shopping", "transport"])
        XCTAssertEqual(content.chart.slices.map(\.value), [0.4, 0.25, 0.13, 0.22])
        XCTAssertEqual(content.chart.centerValue.text, "percent-0.78")
        XCTAssertEqual(content.rows.count, 4)
        XCTAssertEqual(content.rows[0].amount.text, "amount-100.0-USD")
        XCTAssertEqual(content.rows[0].share.text, "share-0.4")
        XCTAssertNotEqual(content.rows[0].tapCommand, .nope)
    }
}

extension AnalyticsPresenterTests {
    func testPresentFetchedDataLoadedEmptyBuildsEmptyState() {
        sut.presentFetchedData(
            .init(
                selectedPeriod: .init(
                    from: Date(timeIntervalSince1970: 1_775_001_600),
                    to: Date(timeIntervalSince1970: 1_775_433_600)
                ),
                loadingState: .loaded,
                data: AnalyticsDataModel(
                    monthStart: Date(timeIntervalSince1970: 1_775_001_600),
                    totalAmount: 0,
                    currency: "USD",
                    categories: []
                )
            )
        )

        guard case let .empty(label) = sut.viewModel.state else {
            return XCTFail("Expected empty state")
        }

        XCTAssertEqual(label.text, L10n.analyticsEmpty)
    }
}

extension AnalyticsPresenterTests {
    func testPresentFetchedDataFailedWithoutDataBuildsErrorState() {
        sut.presentFetchedData(
            .init(
                selectedPeriod: .init(
                    from: Date(timeIntervalSince1970: 1_775_001_600),
                    to: Date(timeIntervalSince1970: 1_775_433_600)
                ),
                loadingState: .failed(.undelinedError(description: "Failed"))
            )
        )

        guard case .error = sut.viewModel.state else {
            return XCTFail("Expected error state")
        }
    }
}

private extension AnalyticsPresenterTests {
    func makeCategory(
        id: String,
        amount: Double,
        share: Double
    ) -> AnalyticsCategorySummaryModel {
        AnalyticsCategorySummaryModel(
            id: id,
            name: id,
            icon: "•",
            colorValue: "light_blue",
            amount: amount,
            currency: "USD",
            share: share,
            isInteractive: true
        )
    }
}

private final class AnalyticsValueFormatterStub: AnalyticsValueFormatting, @unchecked Sendable {
    func formatAmount(_ amount: Double, currencyCode: String) -> String {
        "amount-\(amount)-\(currencyCode)"
    }

    func formatMonth(_ date: Date) -> String {
        "month"
    }

    func formatPeriodTitle(from fromDate: Date, to toDate: Date) -> String {
        "01.04.2026 - 06.04.2026"
    }

    func formatShare(_ share: Double) -> String {
        "share-\(share)"
    }

    func formatPercent(_ share: Double) -> String {
        "percent-\(share)"
    }
}

private final class AnalyticsColorProviderStub: CategoryColorProviding, @unchecked Sendable {
    func color(for value: String) -> UIColor {
        .systemTeal
    }

    func summaryColor(for value: String) -> UIColor {
        .systemBlue
    }

    func accentColor(for value: String) -> UIColor {
        .systemGreen
    }

    func normalizedHex(from value: String) -> String? {
        value
    }

    func hexString(from color: UIColor) -> String? {
        "#00FF00"
    }
}
