import Foundation

struct VylokWidgetSnapshotTimelineResolver: Sendable {
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func resolveSnapshot(
        _ snapshot: VylokWidgetSnapshot?,
        at date: Date
    ) -> VylokWidgetSnapshot? {
        guard let snapshot else {
            return nil
        }

        let fallbackCurrency = snapshot.todayCurrency ?? snapshot.monthCurrency
        let isSameDay = calendar.isDate(snapshot.updatedAt, inSameDayAs: date)
        let isSameMonth = calendar.isDate(
            snapshot.updatedAt,
            equalTo: date,
            toGranularity: .month
        )

        return VylokWidgetSnapshot(
            entitlementState: snapshot.entitlementState,
            todayAmount: isSameDay ? snapshot.todayAmount : .zero,
            todayCurrency: isSameDay ? snapshot.todayCurrency : fallbackCurrency,
            monthAmount: isSameMonth ? snapshot.monthAmount : .zero,
            monthCurrency: isSameMonth ? snapshot.monthCurrency : fallbackCurrency,
            updatedAt: snapshot.updatedAt
        )
    }

    func significantDates(
        for snapshot: VylokWidgetSnapshot?,
        currentDate: Date
    ) -> [Date] {
        guard let snapshot else {
            return []
        }

        var dates: Set<Date> = []

        if calendar.isDate(snapshot.updatedAt, inSameDayAs: currentDate),
           let nextMidnight = nextMidnight(after: currentDate) {
            dates.insert(nextMidnight)
        }

        if calendar.isDate(snapshot.updatedAt, equalTo: currentDate, toGranularity: .month),
           let nextMonthStart = nextMonthStart(after: currentDate) {
            dates.insert(nextMonthStart)
        }

        return dates
            .filter { $0 > currentDate }
            .sorted()
    }

    func nextSignificantDate(
        for snapshot: VylokWidgetSnapshot?,
        currentDate: Date
    ) -> Date? {
        significantDates(
            for: snapshot,
            currentDate: currentDate
        )
        .first
    }
}

private extension VylokWidgetSnapshotTimelineResolver {
    func nextMidnight(after date: Date) -> Date? {
        calendar.date(
            byAdding: .day,
            value: 1,
            to: calendar.startOfDay(for: date)
        )
    }

    func nextMonthStart(after date: Date) -> Date? {
        guard let monthStart = calendar.date(
            from: calendar.dateComponents([.year, .month], from: date)
        ) else {
            return nil
        }

        return calendar.date(
            byAdding: .month,
            value: 1,
            to: monthStart
        )
    }
}
