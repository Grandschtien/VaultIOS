import Foundation

protocol VaultWidgetSnapshotSyncing: Sendable {
    func syncSnapshot() async
    func clearSnapshot()
}

final class VaultWidgetSnapshotSyncService: VaultWidgetSnapshotSyncing, @unchecked Sendable {
    private let summaryService: MainSummaryContractServicing
    private let storage: VaultWidgetSnapshotStoring
    private let timelineReloader: VaultWidgetTimelineReloading
    private let calendar: Calendar
    private let now: @Sendable () -> Date

    init(
        summaryService: MainSummaryContractServicing,
        storage: VaultWidgetSnapshotStoring,
        timelineReloader: VaultWidgetTimelineReloading,
        calendar: Calendar = .current,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.summaryService = summaryService
        self.storage = storage
        self.timelineReloader = timelineReloader
        self.calendar = calendar
        self.now = now
    }

    func syncSnapshot() async {
        let currentDate = now()
        let todayStart = calendar.startOfDay(for: currentDate)
        let monthStart = calendar.date(
            from: calendar.dateComponents([.year, .month], from: currentDate)
        ) ?? todayStart

        async let todaySummary = try? summaryService.getSummary(
            parameters: .init(
                from: todayStart,
                to: currentDate
            )
        )
        async let monthSummary = try? summaryService.getSummary(
            parameters: .init(
                from: monthStart,
                to: currentDate
            )
        )

        guard let resolvedTodaySummary = await todaySummary,
              let resolvedMonthSummary = await monthSummary else {
            return
        }

        storage.saveSnapshot(
            VaultWidgetSnapshot(
                todayAmount: resolvedTodaySummary.total,
                todayCurrency: resolvedTodaySummary.currency,
                monthAmount: resolvedMonthSummary.total,
                monthCurrency: resolvedMonthSummary.currency,
                updatedAt: currentDate
            )
        )
        timelineReloader.reloadTimelines()
    }

    func clearSnapshot() {
        storage.clearSnapshot()
        timelineReloader.reloadTimelines()
    }
}
