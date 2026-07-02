import Foundation

protocol MainFlowRootBusinessLogic: Sendable {
    func handlePendingRouteIfNeeded(isViewVisible: Bool) async
}

actor MainFlowRootInteractor: MainFlowRootBusinessLogic {
    private let context: MainFlowContext
    private let pendingRouteStore: PendingVylokRouteStoring
    private let subscriptionInitializer: SubscriptionInitializerLogic
    private let widgetEntryDestinationResolver: VylokWidgetEntryDestinationResolving
    private let subscriptionAccessService: SubscriptionAccessServicing
    private let widgetSubscriptionOutput: SubscriptionOutput
    private let router: MainFlowRootRoutingLogic

    init(
        context: MainFlowContext,
        pendingRouteStore: PendingVylokRouteStoring,
        subscriptionInitializer: SubscriptionInitializerLogic,
        widgetEntryDestinationResolver: VylokWidgetEntryDestinationResolving,
        subscriptionAccessService: SubscriptionAccessServicing,
        widgetSubscriptionOutput: SubscriptionOutput,
        router: MainFlowRootRoutingLogic
    ) {
        self.context = context
        self.pendingRouteStore = pendingRouteStore
        self.subscriptionInitializer = subscriptionInitializer
        self.widgetEntryDestinationResolver = widgetEntryDestinationResolver
        self.subscriptionAccessService = subscriptionAccessService
        self.widgetSubscriptionOutput = widgetSubscriptionOutput
        self.router = router
    }

    func handlePendingRouteIfNeeded(isViewVisible: Bool) async {
        guard isViewVisible,
              let route = pendingRouteStore.consume() else {
            return
        }

        switch route {
        case .home:
            await router.routeToHome()
        case .aiEntry:
            await subscriptionInitializer.initialize()
            let destination = await widgetEntryDestinationResolver.resolveDestination()
            await router.openWidgetEntry(
                context: context,
                destination: destination
            )
        case .subscription:
            await subscriptionInitializer.initialize()
            let currentTier = await subscriptionAccessService.currentTier()
            await router.openSubscription(
                currentTier: currentTier,
                output: widgetSubscriptionOutput
            )
        }
    }
}
