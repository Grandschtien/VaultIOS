// Created by Egor Shkarin on 05.04.2026

import Foundation

struct MainSummaryPeriod: Equatable, Sendable {
    let from: Date
    let to: Date
}

enum MainPeriodPickerActiveField: Equatable, Sendable {
    case from
    case to
}

struct MainPeriodPickerState: Equatable, Sendable {
    let fromDate: Date
    let toDate: Date
    let activeField: MainPeriodPickerActiveField
    let selectedCalendarDate: Date
    let visibleMonthDate: Date
    let minimumDate: Date
    let maximumDate: Date
    let isApplyEnabled: Bool
}

struct MainPeriodRangeResolver: Sendable {
    let calendar: Calendar

    func defaultPeriod(for currentDate: Date) -> MainSummaryPeriod {
        let normalizedCurrentDate = currentDate
        let monthStart = startOfMonth(for: normalizedCurrentDate)

        return MainSummaryPeriod(
            from: monthStart,
            to: normalizedCurrentDate
        )
    }

    func currentPeriod(
        from fromDate: Date,
        now currentDate: Date
    ) -> MainSummaryPeriod {
        let normalizedFromDate = startOfDay(for: fromDate)

        return MainSummaryPeriod(
            from: normalizedFromDate,
            to: endOfMonthOrNow(for: normalizedFromDate, now: currentDate)
        )
    }

    func resolveStoredPeriod(
        _ period: MainSummaryPeriod?,
        now currentDate: Date
    ) -> MainSummaryPeriod {
        guard let period else {
            return defaultPeriod(for: currentDate)
        }

        return MainSummaryPeriod(
            from: startOfDay(for: period.from),
            to: period.to
        )
    }

    func resolvedPeriod(
        from fromDate: Date,
        to toDate: Date?,
        now currentDate: Date
    ) -> MainSummaryPeriod {
        let normalizedFromDate = startOfDay(for: fromDate)

        if let toDate {
            return MainSummaryPeriod(
                from: normalizedFromDate,
                to: toDate
            )
        }

        return currentPeriod(
            from: normalizedFromDate,
            now: currentDate
        )
    }

    func explicitPeriod(
        from fromDate: Date,
        to toDate: Date,
        now currentDate: Date
    ) -> MainSummaryPeriod {
        return MainSummaryPeriod(
            from: startOfDay(for: fromDate),
            to: normalizedToDate(for: toDate, now: currentDate)
        )
    }

    func pickerState(
        for period: MainSummaryPeriod,
        activeField: MainPeriodPickerActiveField = .to,
        now currentDate: Date
    ) -> MainPeriodPickerState {
        let normalizedFromDate = startOfDay(for: period.from)
        let normalizedToDate = normalizedToDate(for: period.to, now: currentDate)
        let selectedCalendarDate = date(
            for: activeField,
            fromDate: normalizedFromDate,
            toDate: normalizedToDate
        )

        return MainPeriodPickerState(
            fromDate: normalizedFromDate,
            toDate: normalizedToDate,
            activeField: activeField,
            selectedCalendarDate: selectedCalendarDate,
            visibleMonthDate: startOfMonth(for: selectedCalendarDate),
            minimumDate: minimumDate(),
            maximumDate: currentDate,
            isApplyEnabled: normalizedFromDate <= normalizedToDate
        )
    }

    func pickerState(
        from fromDate: Date,
        to toDate: Date,
        activeField: MainPeriodPickerActiveField,
        visibleMonthDate: Date?,
        now currentDate: Date
    ) -> MainPeriodPickerState {
        let normalizedFromDate = startOfDay(for: fromDate)
        let normalizedToDate = normalizedToDate(for: toDate, now: currentDate)
        let selectedCalendarDate = date(
            for: activeField,
            fromDate: normalizedFromDate,
            toDate: normalizedToDate
        )

        return MainPeriodPickerState(
            fromDate: normalizedFromDate,
            toDate: normalizedToDate,
            activeField: activeField,
            selectedCalendarDate: selectedCalendarDate,
            visibleMonthDate: visibleMonthDate.map { startOfMonth(for: $0) } ?? startOfMonth(for: selectedCalendarDate),
            minimumDate: minimumDate(),
            maximumDate: currentDate,
            isApplyEnabled: normalizedFromDate <= normalizedToDate
        )
    }

    func startOfDay(for date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    func startOfMonth(for date: Date) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components).map { calendar.startOfDay(for: $0) } ?? startOfDay(for: date)
    }

    func endOfDayOrNow(
        for date: Date,
        now currentDate: Date
    ) -> Date {
        if calendar.isDate(date, inSameDayAs: currentDate) {
            return currentDate
        }

        guard let dayInterval = calendar.dateInterval(of: .day, for: date) else {
            return currentDate
        }

        return dayInterval.end.addingTimeInterval(-1)
    }

    func endOfMonthOrNow(
        for monthDate: Date,
        now currentDate: Date
    ) -> Date {
        if calendar.isDate(monthDate, equalTo: currentDate, toGranularity: .month) {
            return currentDate
        }

        guard let monthInterval = calendar.dateInterval(of: .month, for: monthDate) else {
            return currentDate
        }

        return monthInterval.end.addingTimeInterval(-1)
    }

    func minimumDate() -> Date {
        calendar.date(
            from: DateComponents(
                calendar: calendar,
                year: 1,
                month: 1,
                day: 1
            )
        ) ?? startOfDay(for: Date.distantPast)
    }

    func normalizedToDate(
        for date: Date,
        now currentDate: Date
    ) -> Date {
        endOfDayOrNow(for: date, now: currentDate)
    }
}

private extension MainPeriodRangeResolver {
    func date(
        for activeField: MainPeriodPickerActiveField,
        fromDate: Date,
        toDate: Date
    ) -> Date {
        switch activeField {
        case .from:
            return fromDate
        case .to:
            return toDate
        }
    }
}

protocol MainSummaryPeriodProviding: Sendable {
    func currentMonthPeriod() -> MainSummaryPeriod
}

protocol MainSummaryPeriodUpdating: Sendable {
    func updatePeriod(from: Date, to: Date)
    func resetToCurrentMonth()
}

typealias MainSummaryPeriodServicing = MainSummaryPeriodProviding & MainSummaryPeriodUpdating

final class MainSummaryPeriodProvider: MainSummaryPeriodServicing, @unchecked Sendable {
    private let lock = NSLock()
    private let now: @Sendable () -> Date
    private let resolver: MainPeriodRangeResolver
    private var selectedPeriod: MainSummaryPeriod?

    init(
        calendar: Calendar = .current,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.now = now
        resolver = MainPeriodRangeResolver(calendar: calendar)
    }

    func currentMonthPeriod() -> MainSummaryPeriod {
        let currentDate = now()
        let storedPeriod = lock.withLock {
            selectedPeriod
        }

        return resolver.resolveStoredPeriod(storedPeriod, now: currentDate)
    }

    func updatePeriod(from: Date, to: Date) {
        let period = resolver.resolvedPeriod(
            from: from,
            to: to,
            now: now()
        )
        lock.withLock {
            selectedPeriod = period
        }
    }

    func resetToCurrentMonth() {
        lock.withLock {
            selectedPeriod = nil
        }
    }
}

private extension NSLock {
    func withLock<T>(_ block: () -> T) -> T {
        lock()
        defer { unlock() }
        return block()
    }
}
