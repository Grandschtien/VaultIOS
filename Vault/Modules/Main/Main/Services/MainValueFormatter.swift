// Created by Egor Shkarin 23.03.2026

import Foundation

protocol MainValueFormatting: Sendable {
    func formatAmount(_ amount: Double, currencyCode: String) -> String
    func formatExpenseAmount(_ amount: Double, currencyCode: String) -> String
    func formatSummaryPeriod(_ date: Date) -> String
    func formatSummaryChange(_ percent: Double) -> String
    func formatSectionDate(_ date: Date, now: Date) -> String
    func formatExpenseTime(_ date: Date, now: Date) -> String
}

struct MainValueFormatter: MainValueFormatting {
    private let localeProvider: @Sendable () -> Locale

    init(localeProvider: @escaping @Sendable () -> Locale = { .current }) {
        self.localeProvider = localeProvider
    }

    func formatAmount(_ amount: Double, currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2

        return formatter.string(from: NSNumber(value: amount))
            ?? "\(currencyCode) \(amount)"
    }

    func formatExpenseAmount(_ amount: Double, currencyCode: String) -> String {
        let formattedAmount = formatAmount(amount, currencyCode: currencyCode)
        return "-\(formattedAmount)"
    }

    func formatSummaryPeriod(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "dd.MM.yyyy"

        return L10n.mainOverviewFromDate(formatter.string(from: date))
    }

    func formatSummaryChange(_ percent: Double) -> String {
        let normalizedPercent = max(0, percent)
        let formattedPercent = String(format: "%.0f%%", normalizedPercent)
        return L10n.mainOverviewFromLastMonth(formattedPercent)
    }

    func formatSectionDate(_ date: Date, now: Date = Date()) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return L10n.mainOverviewToday
        }

        if calendar.isDateInYesterday(date) {
            return L10n.mainOverviewYesterday
        }

        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "dd.MM.yyyy"

        return formatter.string(from: date)
    }

    func formatExpenseTime(_ date: Date, now: Date = Date()) -> String {
        let locale = localeProvider()
        let timeFormatter = DateFormatter()
        timeFormatter.locale = locale
        timeFormatter.dateFormat = expenseTimeDateFormat(for: locale)

        return timeFormatter.string(from: date)
    }

    func expenseTimeDateFormat(for locale: Locale) -> String {
        locale.language.languageCode?.identifier == Locale.LanguageCode.english.identifier
            ? "hh:mm a"
            : "HH:mm"
    }
}
