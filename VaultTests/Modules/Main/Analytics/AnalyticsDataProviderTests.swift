import XCTest
@testable import Vault

final class AnalyticsDataProviderTests: XCTestCase {
    func testFetchDataForwardsCurrentPeriodQueryParameters() async throws {
        let period = MainSummaryPeriod(
            from: makeDate(year: 2026, month: 4, day: 1),
            to: makeDate(year: 2026, month: 4, day: 6, hour: 12)
        )
        let categoriesService = CategoriesServiceStub(
            response: .init(categories: [])
        )
        let sut = AnalyticsDataProvider(
            categoriesService: categoriesService,
            currencyConversionService: CurrencyConversionStub(),
            calendar: calendar
        )

        _ = try await sut.fetchData(for: period)

        XCTAssertEqual(
            categoriesService.capturedParameters,
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
        let categoriesService = CategoriesServiceStub(
            response: .init(categories: [])
        )
        let sut = AnalyticsDataProvider(
            categoriesService: categoriesService,
            currencyConversionService: CurrencyConversionStub(),
            calendar: calendar
        )

        _ = try await sut.fetchData(for: period)

        XCTAssertEqual(
            categoriesService.capturedParameters,
            CategoriesQueryParameters(
                from: period.from,
                to: period.to
            )
        )
    }
}

extension AnalyticsDataProviderTests {
    func testFetchDataMapsFilteredCategoriesAndSortsDescending() async throws {
        let categoriesService = CategoriesServiceStub(
            response: .init(
                categories: [
                    .init(
                        id: "food",
                        name: "Food",
                        icon: "🍔",
                        color: "light_green",
                        totalSpentUsd: 60
                    ),
                    .init(
                        id: "other",
                        name: "Unmapped",
                        icon: "📦",
                        color: "light_blue",
                        totalSpentUsd: 25
                    ),
                    .init(
                        id: "leisure",
                        name: "Leisure",
                        icon: "🎬",
                        color: "light_purple",
                        totalSpentUsd: 15
                    ),
                    .init(
                        id: "zero",
                        name: "Zero",
                        icon: "0",
                        color: "light_gray",
                        totalSpentUsd: 0
                    )
                ]
            )
        )
        let currencyConversion = CurrencyConversionStub(rate: 2, currency: "KZT")
        let sut = AnalyticsDataProvider(
            categoriesService: categoriesService,
            currencyConversionService: currencyConversion,
            calendar: calendar
        )

        let result = try await sut.fetchData(
            for: .init(
                from: makeDate(year: 2026, month: 4, day: 1),
                to: makeDate(year: 2026, month: 4, day: 6, hour: 12)
            )
        )

        XCTAssertEqual(result.totalAmount, 200)
        XCTAssertEqual(result.currency, "KZT")
        XCTAssertEqual(result.categories.map(\.id), ["food", "other", "leisure"])
        XCTAssertEqual(result.categories.map(\.name), ["Food", L10n.other, "Leisure"])
        XCTAssertEqual(result.categories.map(\.icon), ["🍔", "📦", "🎬"])
        XCTAssertEqual(result.categories.map(\.amount), [120, 50, 30])
        XCTAssertEqual(result.categories.map(\.share), [0.6, 0.25, 0.15])
        XCTAssertEqual(result.categories.map(\.isInteractive), [true, true, true])
        XCTAssertEqual(currencyConversion.convertedUsdAmounts, [60, 25, 15, 100])
    }
}

extension AnalyticsDataProviderTests {
    func testFetchDataWithZeroTotalReturnsEmptyCategories() async throws {
        let sut = AnalyticsDataProvider(
            categoriesService: CategoriesServiceStub(
                response: .init(
                    categories: [
                        .init(
                            id: "food",
                            name: "Food",
                            icon: "🍔",
                            color: "light_green",
                            totalSpentUsd: 0
                        )
                    ]
                )
            ),
            currencyConversionService: CurrencyConversionStub(rate: 2, currency: "KZT"),
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

private final class CategoriesServiceStub: MainCategoriesContractServicing, @unchecked Sendable {
    let response: CategoriesResponseDTO
    private(set) var capturedParameters: CategoriesQueryParameters?

    init(response: CategoriesResponseDTO) {
        self.response = response
    }

    func listCategories() async throws -> CategoriesResponseDTO {
        response
    }

    func listCategories(parameters: CategoriesQueryParameters) async throws -> CategoriesResponseDTO {
        capturedParameters = parameters
        return response
    }

    func getCategory(id: String) async throws -> CategoryResponseDTO {
        CategoryResponseDTO(category: response.categories.first ?? .init(id: id, name: "", icon: "", color: "", totalSpentUsd: nil))
    }

    func createCategory(_ request: CategoryCreateRequestDTO) async throws -> CategoryResponseDTO {
        CategoryResponseDTO(
            category: .init(
                id: "created",
                name: request.name,
                icon: request.icon,
                color: request.color,
                totalSpentUsd: nil
            )
        )
    }

    func updateCategory(id: String, request: CategoryCreateRequestDTO) async throws -> CategoryResponseDTO {
        CategoryResponseDTO(
            category: .init(
                id: id,
                name: request.name,
                icon: request.icon,
                color: request.color,
                totalSpentUsd: nil
            )
        )
    }

    func deleteCategory(id: String) async throws {}
}

private final class CurrencyConversionStub: UserCurrencyConverting, @unchecked Sendable {
    let rate: Double
    let currency: String
    private(set) var convertedUsdAmounts: [Double] = []

    init(
        rate: Double = 1,
        currency: String = "USD"
    ) {
        self.rate = rate
        self.currency = currency
    }

    func convertUsdAmount(_ amount: Double) -> UserCurrencyAmount {
        convertedUsdAmounts.append(amount)
        return .init(amount: amount * rate, currency: currency)
    }

    func convertExpense(
        amount: Double,
        currency: String
    ) -> UserCurrencyAmount {
        .init(amount: amount, currency: currency)
    }
}
