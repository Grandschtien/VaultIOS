import Foundation

protocol AnalyticsDataProviding: Sendable {
    func fetchData(for period: MainSummaryPeriod) async throws -> AnalyticsDataModel
}

final class AnalyticsDataProvider: AnalyticsDataProviding, @unchecked Sendable {
    private enum Constants {
        static let unmappedBackendName = "Unmapped"
        static let fallbackIcon = "?"
    }

    private let categoriesService: MainCategoriesContractServicing
    private let currencyConversionService: UserCurrencyConverting
    private let calendar: Calendar

    init(
        categoriesService: MainCategoriesContractServicing,
        currencyConversionService: UserCurrencyConverting,
        calendar: Calendar = .current
    ) {
        self.categoriesService = categoriesService
        self.currencyConversionService = currencyConversionService
        self.calendar = calendar
    }

    func fetchData(for period: MainSummaryPeriod) async throws -> AnalyticsDataModel {
        let categoriesResponse = try await categoriesService.listCategories(
            parameters: .init(
                from: period.from,
                to: period.to
            )
        )
        let totalUsd = categoriesResponse.categories.reduce(into: 0.0) { partialResult, category in
            partialResult += category.totalSpentUsd ?? .zero
        }
        let categories = makeCategorySummaries(
            from: categoriesResponse,
            totalUsd: totalUsd
        )
        let convertedTotal = currencyConversionService.convertUsdAmount(totalUsd)

        return AnalyticsDataModel(
            monthStart: startOfMonth(for: period.from),
            totalAmount: convertedTotal.amount,
            currency: convertedTotal.currency,
            categories: categories.sorted { left, right in
                if left.amount == right.amount {
                    return left.name.localizedCaseInsensitiveCompare(right.name) == .orderedAscending
                }

                return left.amount > right.amount
            }
        )
    }
}

private extension AnalyticsDataProvider {
    func makeCategorySummaries(
        from response: CategoriesResponseDTO,
        totalUsd: Double
    ) -> [AnalyticsCategorySummaryModel] {
        guard totalUsd > .zero else {
            return []
        }

        return response.categories.compactMap { category in
            let usdAmount = category.totalSpentUsd ?? .zero
            guard usdAmount > .zero else {
                return nil
            }

            let convertedAmount = currencyConversionService.convertUsdAmount(usdAmount)

            return AnalyticsCategorySummaryModel(
                id: category.id,
                name: localizedCategoryName(from: category.name),
                icon: category.icon.isEmpty ? Constants.fallbackIcon : category.icon,
                colorValue: category.color,
                amount: convertedAmount.amount,
                currency: convertedAmount.currency,
                share: usdAmount / totalUsd,
                isInteractive: true
            )
        }
    }

    func localizedCategoryName(from backendName: String) -> String {
        if backendName.compare(Constants.unmappedBackendName, options: [.caseInsensitive]) == .orderedSame {
            return L10n.other
        }

        return backendName
    }

    func startOfMonth(for date: Date) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components).map { calendar.startOfDay(for: $0) } ?? calendar.startOfDay(for: date)
    }
}
