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

    init(
        presenter: ExpenseEntryChooserPresentationLogic,
        router: ExpenseEntryChooserRoutingLogic,
        subscriptionAccessService: SubscriptionAccessServicing
    ) {
        self.presenter = presenter
        self.router = router
        self.subscriptionAccessService = subscriptionAccessService
    }

    func fetchData() async {
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
