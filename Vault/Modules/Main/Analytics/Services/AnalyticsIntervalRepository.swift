import Foundation

protocol AnalyticsIntervalRepositoryProtocol: Sendable {
    func cachedData(for resolution: AnalyticsPeriodResolution) async -> AnalyticsDataModel?
    func save(data: AnalyticsDataModel, for resolution: AnalyticsPeriodResolution) async
    func invalidateIntersecting(with dates: [Date]) async
    func clear() async
}

actor AnalyticsIntervalRepository: AnalyticsIntervalRepositoryProtocol {
    private struct CachedInterval {
        let resolution: AnalyticsPeriodResolution
        let data: AnalyticsDataModel
    }

    private let calendar: Calendar
    private let weekCalendar: Calendar
    private var cachedIntervals: [CachedInterval] = []

    init(calendar: Calendar = .current) {
        self.calendar = calendar
        var weekCalendar = calendar
        weekCalendar.firstWeekday = 2
        weekCalendar.minimumDaysInFirstWeek = 4
        self.weekCalendar = weekCalendar
    }

    func cachedData(for resolution: AnalyticsPeriodResolution) -> AnalyticsDataModel? {
        cachedIntervals.first {
            matches(
                $0.resolution,
                requestedResolution: resolution
            )
        }?.data
    }

    func save(data: AnalyticsDataModel, for resolution: AnalyticsPeriodResolution) {
        cachedIntervals.removeAll {
            matches(
                $0.resolution,
                requestedResolution: resolution
            )
        }
        cachedIntervals.append(
            CachedInterval(
                resolution: resolution,
                data: data
            )
        )
    }

    func invalidateIntersecting(with dates: [Date]) {
        guard dates.isEmpty == false else {
            return
        }

        cachedIntervals.removeAll { cachedInterval in
            dates.contains { date in
                intersects(
                    date,
                    with: cachedInterval.resolution
                )
            }
        }
    }

    func clear() {
        cachedIntervals.removeAll()
    }
}

private extension AnalyticsIntervalRepository {
    func matches(
        _ cachedResolution: AnalyticsPeriodResolution,
        requestedResolution: AnalyticsPeriodResolution
    ) -> Bool {
        switch requestedResolution.preset {
        case let .some(requestedPreset):
            guard cachedResolution.preset == requestedPreset else {
                return false
            }

            guard cachedResolution.period.from == requestedResolution.period.from else {
                return false
            }

            return calendar.isDate(
                cachedResolution.period.to,
                inSameDayAs: requestedResolution.period.to
            )
        case .none:
            guard cachedResolution.preset == nil else {
                return false
            }

            return cachedResolution.period.from == requestedResolution.period.from
                && cachedResolution.period.to == requestedResolution.period.to
        }
    }

    func intersects(
        _ date: Date,
        with resolution: AnalyticsPeriodResolution
    ) -> Bool {
        let effectivePeriod = effectivePeriod(for: resolution)
        return date >= effectivePeriod.from && date <= effectivePeriod.to
    }

    func effectivePeriod(
        for resolution: AnalyticsPeriodResolution
    ) -> MainSummaryPeriod {
        guard let preset = resolution.preset else {
            return resolution.period
        }

        switch preset {
        case .day:
            let dayStart = calendar.startOfDay(for: resolution.period.from)
            return MainSummaryPeriod(
                from: dayStart,
                to: end(of: .day, containing: dayStart, calendar: calendar)
            )
        case .week:
            let weekStart = startOfWeek(for: resolution.period.from)
            return MainSummaryPeriod(
                from: weekStart,
                to: end(of: .weekOfYear, containing: weekStart, calendar: weekCalendar)
            )
        case .month:
            let monthStart = startOfMonth(for: resolution.period.from)
            return MainSummaryPeriod(
                from: monthStart,
                to: end(of: .month, containing: monthStart, calendar: calendar)
            )
        }
    }

    func startOfWeek(for date: Date) -> Date {
        guard let interval = weekCalendar.dateInterval(of: .weekOfYear, for: date) else {
            return calendar.startOfDay(for: date)
        }

        return weekCalendar.startOfDay(for: interval.start)
    }

    func startOfMonth(for date: Date) -> Date {
        guard let interval = calendar.dateInterval(of: .month, for: date) else {
            return calendar.startOfDay(for: date)
        }

        return calendar.startOfDay(for: interval.start)
    }

    func end(
        of component: Calendar.Component,
        containing date: Date,
        calendar: Calendar
    ) -> Date {
        guard let interval = calendar.dateInterval(of: component, for: date) else {
            return date
        }

        return interval.end.addingTimeInterval(-1)
    }
}
