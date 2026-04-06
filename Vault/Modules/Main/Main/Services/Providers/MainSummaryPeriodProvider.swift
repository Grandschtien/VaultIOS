// Created by Egor Shkarin on 05.04.2026

import Foundation

struct MainSummaryPeriod: Equatable, Sendable {
    let from: Date
    let to: Date
}

protocol MainSummaryPeriodProviding: Sendable {
    func currentMonthPeriod() -> MainSummaryPeriod
}

protocol MainSummaryPeriodUpdating: Sendable {
    func updateFromDate(_ fromDate: Date)
}

typealias MainSummaryPeriodServicing = MainSummaryPeriodProviding & MainSummaryPeriodUpdating

final class MainSummaryPeriodProvider: MainSummaryPeriodServicing, @unchecked Sendable {
    private let lock = NSLock()
    private let calendar: Calendar
    private let now: @Sendable () -> Date
    private var selectedFromDate: Date?

    init(
        calendar: Calendar = .current,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.calendar = calendar
        self.now = now
    }

    func currentMonthPeriod() -> MainSummaryPeriod {
        let currentDate = now()
        let startOfPeriod = lock.withLock {
            selectedFromDate ?? defaultStartOfMonth(for: currentDate)
        }

        return MainSummaryPeriod(
            from: startOfPeriod,
            to: currentDate
        )
    }

    func updateFromDate(_ fromDate: Date) {
        let normalizedDate = calendar.startOfDay(for: fromDate)
        lock.withLock {
            selectedFromDate = normalizedDate
        }
    }
}

private extension MainSummaryPeriodProvider {
    func defaultStartOfMonth(for currentDate: Date) -> Date {
        var startComponents = calendar.dateComponents([.year, .month], from: currentDate)
        startComponents.day = 1

        return calendar.date(from: startComponents) ?? currentDate
    }
}

private extension NSLock {
    func withLock<T>(_ block: () -> T) -> T {
        lock()
        defer { unlock() }
        return block()
    }
}
