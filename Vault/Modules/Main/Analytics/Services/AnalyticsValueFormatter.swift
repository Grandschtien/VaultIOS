import Foundation

protocol AnalyticsValueFormatting: Sendable {
    func formatAmount(_ amount: Double, currencyCode: String) -> String
    func formatMonth(_ date: Date) -> String
    func formatPeriodTitle(from fromDate: Date, to toDate: Date) -> String
    func formatShare(_ share: Double) -> String
    func formatPercent(_ share: Double) -> String
}

struct AnalyticsValueFormatter: AnalyticsValueFormatting {
    private let amountFormatter: MainValueFormatting
    private let localeProvider: @Sendable () -> Locale

    init(
        amountFormatter: MainValueFormatting = MainValueFormatter(),
        localeProvider: @escaping @Sendable () -> Locale = { .current }
    ) {
        self.amountFormatter = amountFormatter
        self.localeProvider = localeProvider
    }

    func formatAmount(_ amount: Double, currencyCode: String) -> String {
        amountFormatter.formatAmount(amount, currencyCode: currencyCode)
    }

    func formatMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = localeProvider()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date).capitalized(with: formatter.locale)
    }

    func formatPeriodTitle(from fromDate: Date, to toDate: Date) -> String {
        "\(formatDate(fromDate)) - \(formatDate(toDate))"
    }

    func formatShare(_ share: Double) -> String {
        L10n.analyticsOfTotal(formatPercent(share))
    }

    func formatPercent(_ share: Double) -> String {
        let normalizedShare = min(max(share, .zero), 1)
        let percentage = Int((normalizedShare * 100).rounded())
        return "\(percentage)%"
    }
}

private extension AnalyticsValueFormatter {
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = localeProvider()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: date)
    }
}
