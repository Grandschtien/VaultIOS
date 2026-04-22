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
    private let calendar: Calendar

    init(
        categoriesService: MainCategoriesContractServicing,
        calendar: Calendar = .current
    ) {
        self.categoriesService = categoriesService
        self.calendar = calendar
    }

    func fetchData(for period: MainSummaryPeriod) async throws -> AnalyticsDataModel {
        let categoriesResponse = try await categoriesService.listCategories(
            parameters: .init(
                from: period.from,
                to: period.to
            )
        )
        let totalAmount = categoriesResponse.categories.reduce(into: 0.0) { partialResult, category in
            partialResult += category.displayedAmount
        }
        let categories = makeCategorySummaries(
            from: categoriesResponse,
            totalAmount: totalAmount
        )
        let currency = categoriesResponse.categories.first?.displayedCurrency ?? "USD"

        return AnalyticsDataModel(
            monthStart: startOfMonth(for: period.from),
            totalAmount: totalAmount,
            currency: currency,
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
        totalAmount: Double
    ) -> [AnalyticsCategorySummaryModel] {
        guard totalAmount > .zero else {
            return []
        }

        return response.categories.compactMap { category in
            let displayedAmount = category.displayedAmount
            guard displayedAmount > .zero else {
                return nil
            }

            return AnalyticsCategorySummaryModel(
                id: category.id,
                name: localizedCategoryName(from: category.name),
                icon: category.icon.isEmpty ? Constants.fallbackIcon : category.icon,
                colorValue: category.color,
                amount: displayedAmount,
                currency: category.displayedCurrency,
                share: displayedAmount / totalAmount,
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
