import Foundation

enum AnalyticsPeriodPreset: CaseIterable, Equatable, Hashable, Sendable {
    case day
    case week
    case month
}

struct AnalyticsPeriodResolution: Equatable, Sendable {
    let period: MainSummaryPeriod
    let preset: AnalyticsPeriodPreset?
}

protocol AnalyticsPeriodResolving: Sendable {
    func defaultPeriod() -> AnalyticsPeriodResolution
    func resolveCurrentPeriod(for preset: AnalyticsPeriodPreset) -> AnalyticsPeriodResolution
    func resolvePeriod(from: Date, to: Date) -> AnalyticsPeriodResolution
    func previousPeriod(for resolution: AnalyticsPeriodResolution) -> AnalyticsPeriodResolution
}

final class AnalyticsPeriodResolver: AnalyticsPeriodResolving {
    private let now: @Sendable () -> Date
    private let periodResolver: MainPeriodRangeResolver
    private let weekCalendar: Calendar
    init(calendar: Calendar = .current, now: @escaping @Sendable () -> Date = Date.init) {
        self.now = now
        periodResolver = MainPeriodRangeResolver(calendar: calendar)
        var weekCalendar = calendar
        weekCalendar.firstWeekday = 2
        weekCalendar.minimumDaysInFirstWeek = 4
        self.weekCalendar = weekCalendar
    }

    func defaultPeriod() -> AnalyticsPeriodResolution {
        .init(period: periodResolver.defaultPeriod(for: now()), preset: .month)
    }

    func resolveCurrentPeriod(for preset: AnalyticsPeriodPreset) -> AnalyticsPeriodResolution {
        let currentDate = now()
        return .init(
            period: makePresetPeriod(
                preset,
                anchorDate: currentDate,
                currentDate: currentDate
            ),
            preset: preset
        )
    }

    func resolvePeriod(from: Date, to: Date) -> AnalyticsPeriodResolution {
        let currentDate = now()
        let period = periodResolver.explicitPeriod(from: from, to: to, now: currentDate)

        for preset in AnalyticsPeriodPreset.allCases {
            let candidate = makePresetPeriod(preset, anchorDate: period.from, currentDate: currentDate)
            if candidate == period {
                return .init(period: period, preset: preset)
            }
        }

        return .init(period: period, preset: nil)
    }

    func previousPeriod(for resolution: AnalyticsPeriodResolution) -> AnalyticsPeriodResolution {
        guard let preset = resolution.preset else {
            return resolution
        }

        let anchorDate: Date
        switch preset {
        case .day:
            anchorDate = weekCalendar.date(byAdding: .day, value: -1, to: resolution.period.from) ?? resolution.period.from
        case .week:
            anchorDate = weekCalendar.date(byAdding: .weekOfYear, value: -1, to: resolution.period.from) ?? resolution.period.from
        case .month:
            anchorDate = weekCalendar.date(byAdding: .month, value: -1, to: resolution.period.from) ?? resolution.period.from
        }

        return .init(period: makePresetPeriod(preset, anchorDate: anchorDate, currentDate: now()), preset: preset)
    }
}

private extension AnalyticsPeriodResolver {
    func makePresetPeriod(_ preset: AnalyticsPeriodPreset, anchorDate: Date, currentDate: Date) -> MainSummaryPeriod {
        switch preset {
        case .day:
            let dayStart = periodResolver.startOfDay(for: anchorDate)
            return .init(from: dayStart, to: periodResolver.endOfDayOrNow(for: anchorDate, now: currentDate))
        case .week:
            let weekStart = startOfWeek(for: anchorDate)
            return .init(from: weekStart, to: endOfWeekOrNow(for: anchorDate, now: currentDate))
        case .month:
            let monthStart = periodResolver.startOfMonth(for: anchorDate)
            return .init(from: monthStart, to: periodResolver.endOfMonthOrNow(for: anchorDate, now: currentDate))
        }
    }

    func startOfWeek(for date: Date) -> Date {
        guard let weekInterval = weekCalendar.dateInterval(of: .weekOfYear, for: date) else {
            return periodResolver.startOfDay(for: date)
        }
        return weekCalendar.startOfDay(for: weekInterval.start)
    }

    func endOfWeekOrNow(for date: Date, now currentDate: Date) -> Date {
        if startOfWeek(for: date) == startOfWeek(for: currentDate) {
            return currentDate
        }
        guard let weekInterval = weekCalendar.dateInterval(of: .weekOfYear, for: date) else {
            return currentDate
        }
        return weekInterval.end.addingTimeInterval(-1)
    }
}
