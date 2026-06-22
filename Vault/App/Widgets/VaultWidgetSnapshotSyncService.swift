import Foundation

protocol VaultWidgetSnapshotSyncing: Sendable {
    func syncSnapshot() async
    func clearSnapshot()
}

final class VaultWidgetSnapshotSyncService: VaultWidgetSnapshotSyncing, @unchecked Sendable {
    private let summaryService: MainSummaryContractServicing
    private let userProfileStorageService: UserProfileStorageServiceProtocol
    private let subscriptionAccessService: SubscriptionAccessServicing
    private let storage: VaultWidgetSnapshotStoring
    private let timelineReloader: VaultWidgetTimelineReloading
    private let entitlementStateResolver: VaultWidgetEntitlementStateResolver
    private let calendar: Calendar
    private let now: @Sendable () -> Date

    init(
        summaryService: MainSummaryContractServicing,
        userProfileStorageService: UserProfileStorageServiceProtocol,
        subscriptionAccessService: SubscriptionAccessServicing,
        storage: VaultWidgetSnapshotStoring,
        timelineReloader: VaultWidgetTimelineReloading,
        entitlementStateResolver: VaultWidgetEntitlementStateResolver = VaultWidgetEntitlementStateResolver(),
        calendar: Calendar = .current,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.summaryService = summaryService
        self.userProfileStorageService = userProfileStorageService
        self.subscriptionAccessService = subscriptionAccessService
        self.storage = storage
        self.timelineReloader = timelineReloader
        self.entitlementStateResolver = entitlementStateResolver
        self.calendar = calendar
        self.now = now
    }

    func syncSnapshot() async {
        guard userProfileStorageService.loadProfile() != nil else {
            clearSnapshot()
            return
        }

        let currentDate = now()
        let fallbackSnapshot = storage.loadSnapshot()
        let todayStart = calendar.startOfDay(for: currentDate)
        let monthStart = calendar.date(
            from: calendar.dateComponents([.year, .month], from: currentDate)
        ) ?? todayStart
        let entitlementState = await resolveEntitlementState()

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

        let resolvedTodaySummary = await todaySummary
        let resolvedMonthSummary = await monthSummary

        storage.saveSnapshot(
            VaultWidgetSnapshot(
                entitlementState: entitlementState,
                todayAmount: resolvedTodaySummary?.total ?? fallbackSnapshot?.todayAmount,
                todayCurrency: resolvedTodaySummary?.currency ?? fallbackSnapshot?.todayCurrency,
                monthAmount: resolvedMonthSummary?.total ?? fallbackSnapshot?.monthAmount,
                monthCurrency: resolvedMonthSummary?.currency ?? fallbackSnapshot?.monthCurrency,
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

private extension VaultWidgetSnapshotSyncService {
    func resolveEntitlementState() async -> VaultWidgetEntitlementState {
        if let currentSnapshot = await subscriptionAccessService.currentSubscriptionSnapshot() {
            return entitlementStateResolver.resolve(from: currentSnapshot)
        }

        if let refreshedSnapshot = await subscriptionAccessService.refreshCurrentSubscriptionSnapshot() {
            return entitlementStateResolver.resolve(from: refreshedSnapshot)
        }

        return .regular
    }
}
