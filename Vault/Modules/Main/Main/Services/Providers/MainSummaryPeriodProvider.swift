// Created by Codex on 05.04.2026

import Foundation

struct MainSummaryPeriod: Equatable, Sendable {
    let from: Date
    let to: Date
}

protocol MainSummaryPeriodProviding: Sendable {
    func currentMonthPeriod() -> MainSummaryPeriod
}

struct MainSummaryPeriodProvider: MainSummaryPeriodProviding {
    private let calendar: Calendar
    private let now: @Sendable () -> Date

    init(
        calendar: Calendar = .current,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.calendar = calendar
        self.now = now
    }

    func currentMonthPeriod() -> MainSummaryPeriod {
        let currentDate = now()
        var startComponents = calendar.dateComponents([.year, .month], from: currentDate)
        startComponents.day = 1

        let startOfMonth = calendar.date(from: startComponents) ?? currentDate

        return MainSummaryPeriod(
            from: startOfMonth,
            to: currentDate
        )
    }
}
