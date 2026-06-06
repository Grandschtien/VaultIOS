import Foundation

protocol ExpenseEntryChooserBusinessLogic: Sendable {
    func fetchData() async
}

protocol ExpenseEntryChooserHandler: AnyObject, Sendable {
    func handleTapClose() async
    func handleTapAiEntry() async
    func handleTapManualEntry() async
}

actor ExpenseEntryChooserInteractor: ExpenseEntryChooserBusinessLogic {
    private enum Constants {
        static let regularTier = "REGULAR"
    }

    private let presenter: ExpenseEntryChooserPresentationLogic
    private let router: ExpenseEntryChooserRoutingLogic
    private let subscriptionAccessService: SubscriptionAccessServicing
    private let analytics: ExpenseEntryChooserAnalyticsTracking?

    init(
        presenter: ExpenseEntryChooserPresentationLogic,
        router: ExpenseEntryChooserRoutingLogic,
        subscriptionAccessService: SubscriptionAccessServicing,
        analytics: ExpenseEntryChooserAnalyticsTracking? = nil
    ) {
        self.presenter = presenter
        self.router = router
        self.subscriptionAccessService = subscriptionAccessService
        self.analytics = analytics
    }

    func fetchData() async {
        analytics?.trackScreenOpen()
        await presenter.presentFetchedData(.init())
    }
}

extension ExpenseEntryChooserInteractor: ExpenseEntryChooserHandler {
    func handleTapClose() async {
        await router.close()
    }

    func handleTapAiEntry() async {
        let subscription = await subscriptionAccessService.currentSubscriptionSnapshot()
        let currentTier = subscription?.tier ?? .regular

        guard subscription?.hasAiInputAccess == true else {
            analytics?.trackPaywallOpen(currentTier: currentTier.rawValue)
            await router.openSubscription(
                currentTier: currentTier,
                output: self
            )
            return
        }

        await router.openAiEntry()
    }

    func handleTapManualEntry() async {
        await router.openManualEntry()
    }
}

extension ExpenseEntryChooserInteractor: SubscriptionOutput {
    func handleSubscriptionDidSync() async {
        _ = await subscriptionAccessService.refreshCurrentSubscriptionSnapshot()
    }
}
