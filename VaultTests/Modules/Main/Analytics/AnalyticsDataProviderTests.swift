import XCTest
@testable import Vylok

final class AnalyticsDataProviderTests: XCTestCase {
    func testFetchDataForwardsCurrentPeriodQueryParameters() async throws {
        let period = MainSummaryPeriod(
            from: makeDate(year: 2026, month: 4, day: 1),
            to: makeDate(year: 2026, month: 4, day: 6, hour: 12)
        )
        let categoriesService = MainCategoriesContractServicingMock()
        categoriesService.listCategoriesParametersReturnValue = .init(categories: [])
        let sut = AnalyticsDataProvider(
            categoriesService: categoriesService,
            calendar: calendar
        )

        _ = try await sut.fetchData(for: period)

        XCTAssertEqual(
            categoriesService.listCategoriesParametersReceivedArguments,
            CategoriesQueryParameters(
                from: period.from,
                to: period.to
            )
        )
    }
}

extension AnalyticsDataProviderTests {
    func testFetchDataPreservesExplicitPastPeriodUpperBound() async throws {
        let period = MainSummaryPeriod(
            from: makeDate(year: 2026, month: 3, day: 15),
            to: makeDate(year: 2026, month: 3, day: 31, hour: 23, minute: 59, second: 59)
        )
        let categoriesService = MainCategoriesContractServicingMock()
        categoriesService.listCategoriesParametersReturnValue = .init(categories: [])
        let sut = AnalyticsDataProvider(
            categoriesService: categoriesService,
            calendar: calendar
        )

        _ = try await sut.fetchData(for: period)

        XCTAssertEqual(
            categoriesService.listCategoriesParametersReceivedArguments,
            CategoriesQueryParameters(
                from: period.from,
                to: period.to
            )
        )
    }
}

extension AnalyticsDataProviderTests {
    func testFetchDataMapsFilteredCategoriesAndSortsDescending() async throws {
        let categoriesService = MainCategoriesContractServicingMock()
        categoriesService.listCategoriesParametersReturnValue = .init(
            categories: [
                .init(
                    id: "food",
                    name: "Food",
                    icon: "🍔",
                    color: "light_green",
                    totalSpent: 60,
                    currency: "KZT"
                ),
                .init(
                    id: "other",
                    name: "Unmapped",
                    icon: "📦",
                    color: "light_blue",
                    totalSpent: 25,
                    currency: "KZT"
                ),
                .init(
                    id: "leisure",
                    name: "Leisure",
                    icon: "🎬",
                    color: "light_purple",
                    totalSpent: 15,
                    currency: "KZT"
                ),
                .init(
                    id: "zero",
                    name: "Zero",
                    icon: "0",
                    color: "light_gray",
                    totalSpent: 0,
                    currency: "KZT"
                )
            ]
        )
        let sut = AnalyticsDataProvider(
            categoriesService: categoriesService,
            calendar: calendar
        )

        let result = try await sut.fetchData(
            for: .init(
                from: makeDate(year: 2026, month: 4, day: 1),
                to: makeDate(year: 2026, month: 4, day: 6, hour: 12)
            )
        )

        XCTAssertEqual(result.totalAmount, 100)
        XCTAssertEqual(result.currency, "KZT")
        XCTAssertEqual(result.categories.map(\.id), ["food", "other", "leisure"])
        XCTAssertEqual(result.categories.map(\.name), ["Food", L10n.other, "Leisure"])
        XCTAssertEqual(result.categories.map(\.icon), ["🍔", "📦", "🎬"])
        XCTAssertEqual(result.categories.map(\.amount), [60, 25, 15])
        XCTAssertEqual(result.categories.map(\.share), [0.6, 0.25, 0.15])
        XCTAssertEqual(result.categories.map(\.isInteractive), [true, true, true])
    }
}

extension AnalyticsDataProviderTests {
    func testFetchDataWithZeroTotalReturnsEmptyCategories() async throws {
        let categoriesService = MainCategoriesContractServicingMock()
        categoriesService.listCategoriesParametersReturnValue = .init(
            categories: [
                .init(
                    id: "food",
                    name: "Food",
                    icon: "🍔",
                    color: "light_green",
                    totalSpent: 0,
                    currency: "KZT"
                )
            ]
        )
        let sut = AnalyticsDataProvider(
            categoriesService: categoriesService,
            calendar: calendar
        )

        let result = try await sut.fetchData(
            for: .init(
                from: makeDate(year: 2026, month: 4, day: 1),
                to: makeDate(year: 2026, month: 4, day: 6, hour: 12)
            )
        )

        XCTAssertTrue(result.categories.isEmpty)
        XCTAssertTrue(result.isEmpty)
    }
}

private extension AnalyticsDataProviderTests {
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar
    }

    func makeDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0,
        minute: Int = 0,
        second: Int = 0
    ) -> Date {
        calendar.date(
            from: DateComponents(
                timeZone: calendar.timeZone,
                year: year,
                month: month,
                day: day,
                hour: hour,
                minute: minute,
                second: second
            )
        ) ?? .distantPast
    }
}
