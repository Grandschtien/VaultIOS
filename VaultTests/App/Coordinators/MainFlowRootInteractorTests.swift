import XCTest
@testable import Vylok

final class MainFlowRootInteractorTests: XCTestCase {
    private var context: MainFlowContext!
    private var pendingRouteStore: PendingVylokRouteStoringMock!
    private var subscriptionInitializer: SubscriptionInitializerLogicMock!
    private var widgetEntryDestinationResolver: VylokWidgetEntryDestinationResolvingMock!
    private var subscriptionAccessService: SubscriptionAccessServicingMock!
    private var widgetSubscriptionOutput: SubscriptionOutputMock!
    private var router: MainFlowRootRoutingLogicMock!
    private var sut: MainFlowRootInteractor!

    override func setUp() {
        super.setUp()
        context = MainFlowContext(
            store: MainFlowDomainStoreProtocolMock(),
            observer: MainFlowDomainObserverProtocolMock(),
            repository: MainFlowDomainRepositoryProtocolMock(),
            analyticsIntervalRepository: AnalyticsIntervalRepositoryProtocolMock(),
            summaryPeriodProvider: MainSummaryPeriodProvider()
        )
        pendingRouteStore = PendingVylokRouteStoringMock()
        subscriptionInitializer = SubscriptionInitializerLogicMock()
        widgetEntryDestinationResolver = VylokWidgetEntryDestinationResolvingMock()
        subscriptionAccessService = SubscriptionAccessServicingMock()
        widgetSubscriptionOutput = SubscriptionOutputMock()
        router = MainFlowRootRoutingLogicMock()
        sut = MainFlowRootInteractor(
            context: context,
            pendingRouteStore: pendingRouteStore,
            subscriptionInitializer: subscriptionInitializer,
            widgetEntryDestinationResolver: widgetEntryDestinationResolver,
            subscriptionAccessService: subscriptionAccessService,
            widgetSubscriptionOutput: widgetSubscriptionOutput,
            router: router
        )
    }

    override func tearDown() {
        sut = nil
        router = nil
        widgetSubscriptionOutput = nil
        subscriptionAccessService = nil
        widgetEntryDestinationResolver = nil
        subscriptionInitializer = nil
        pendingRouteStore = nil
        context = nil
        super.tearDown()
    }
}

// MARK: - handlePendingRouteIfNeeded

extension MainFlowRootInteractorTests {
    func testHandlePendingRouteIfNeededWhenRouteIsHomeRoutesHome() async {
        // Arrange
        pendingRouteStore.consumeReturnValue = .home

        // Act
        await sut.handlePendingRouteIfNeeded(isViewVisible: true)

        // Assert
        XCTAssertEqual(router.routeToHomeCallsCount, 1)
        XCTAssertFalse(subscriptionInitializer.initializeCalled)
    }

    func testHandlePendingRouteIfNeededWhenRouteIsAIEntryOpensResolvedWidgetEntry() async throws {
        // Arrange
        pendingRouteStore.consumeReturnValue = .aiEntry
        widgetEntryDestinationResolver.resolveDestinationReturnValue = .manualEntry

        // Act
        await sut.handlePendingRouteIfNeeded(isViewVisible: true)

        // Assert
        XCTAssertEqual(subscriptionInitializer.initializeCallsCount, 1)
        XCTAssertEqual(router.openWidgetEntryContextDestinationCallsCount, 1)
        let arguments = try XCTUnwrap(router.openWidgetEntryContextDestinationReceivedArguments)
        XCTAssertTrue(arguments.context === context)
        XCTAssertEqual(arguments.destination, .manualEntry)
    }

    func testHandlePendingRouteIfNeededWhenRouteIsSubscriptionOpensSubscriptionWithCurrentTier() async throws {
        // Arrange
        pendingRouteStore.consumeReturnValue = .subscription
        subscriptionAccessService.currentTierStateReturnValue = .resolved(.premium)

        // Act
        await sut.handlePendingRouteIfNeeded(isViewVisible: true)

        // Assert
        XCTAssertEqual(subscriptionInitializer.initializeCallsCount, 1)
        XCTAssertEqual(router.openSubscriptionCurrentTierOutputCallsCount, 1)
        let arguments = try XCTUnwrap(router.openSubscriptionCurrentTierOutputReceivedArguments)
        XCTAssertEqual(arguments.currentTier, .premium)
        XCTAssertTrue(arguments.output === widgetSubscriptionOutput)
    }

    func testHandlePendingRouteIfNeededWhenViewIsNotVisibleKeepsPendingRoute() async {
        // Arrange
        pendingRouteStore.consumeReturnValue = .aiEntry

        // Act
        await sut.handlePendingRouteIfNeeded(isViewVisible: false)

        // Assert
        XCTAssertFalse(pendingRouteStore.consumeCalled)
        XCTAssertFalse(router.openWidgetEntryContextDestinationCalled)
    }
}
