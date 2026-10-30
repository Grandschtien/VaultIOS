import XCTest
@testable import Vylok

@MainActor
final class AnalyticsInteractorTests: XCTestCase {
    func testFetchDataLoadsCurrentAnalyticsPeriod() async {
        let presenter = AnalyticsPresentationLogicMock()
        let dataProvider = Self.makeDataProvider(
            results: [.success(makeData(monthStart: aprilStart, totalAmount: 120))]
        )
        let sut = AnalyticsInteractor(
            presenter: presenter,
            router: AnalyticsRoutingLogicMock(),
            repository: MainFlowDomainRepositoryProtocolMock(),
            dataProvider: dataProvider,
            observer: Self.makeObserver().observer,
            periodResolver: makePeriodResolver(),
            subscriptionAccessService: Self.makeSubscriptionAccessService(currentTier: "PREMIUM")
        )

        await sut.fetchData()

        let fetchCalls = dataProvider.fetchDataForReceivedInvocations
        XCTAssertEqual(fetchCalls, [aprilCurrentPeriod])
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.first?.loadingState, .loading)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.loadingState, .loaded)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.data?.totalAmount, 120)
    }

    func testFetchDataUsesAnalyticsCapabilityInsteadOfTier() async {
        let presenter = AnalyticsPresentationLogicMock()
        let dataProvider = Self.makeDataProvider(
            results: [.success(makeData(monthStart: aprilStart, totalAmount: 120))]
        )
        let sut = AnalyticsInteractor(
            presenter: presenter,
            router: AnalyticsRoutingLogicMock(),
            repository: MainFlowDomainRepositoryProtocolMock(),
            dataProvider: dataProvider,
            observer: Self.makeObserver().observer,
            periodResolver: makePeriodResolver(),
            subscriptionAccessService: Self.makeSubscriptionAccessService(
                currentTier: "REGULAR",
                currentSnapshot: .init(
                    tier: .regular,
                    status: .active,
                    paidAccessUntil: nil,
                    capabilities: [.analytics],
                    aiRequestsLimit: 0,
                    aiRequestsRemaining: 0,
                    statusVersion: 42
                )
            )
        )

        await sut.fetchData()

        let fetchCalls = dataProvider.fetchDataForReceivedInvocations
        XCTAssertEqual(fetchCalls, [aprilCurrentPeriod])
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.isLocked, false)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.loadingState, .loaded)
    }
}

extension AnalyticsInteractorTests {
    func testFetchDataWhenTierStateIsUnavailableShowsErrorInsteadOfLockedState() async {
        let presenter = AnalyticsPresentationLogicMock()
        let (observer, _) = Self.makeObserver()
        let dataProvider = Self.makeDataProvider(results: [])
        let sut = AnalyticsInteractor(
            presenter: presenter,
            router: AnalyticsRoutingLogicMock(),
            repository: MainFlowDomainRepositoryProtocolMock(),
            dataProvider: dataProvider,
            observer: observer,
            periodResolver: makePeriodResolver(),
            subscriptionAccessService: Self.makeSubscriptionAccessService(currentTierState: .unavailable)
        )

        await sut.fetchData()
        let recordedFetchCalls = dataProvider.fetchDataForReceivedInvocations

        XCTAssertEqual(recordedFetchCalls, [])
        XCTAssertEqual(observer.subscribeOverviewCallsCount, 0)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.isLocked, false)

        guard case .failed = presenter.presentFetchedDataReceivedInvocations.last?.loadingState else {
            return XCTFail("Expected Analytics to show an error state when tier resolution is unavailable")
        }
    }
}

extension AnalyticsInteractorTests {
    func testHandleTapRetryKeepsLoadedDataWhenRefreshFails() async {
        let presenter = AnalyticsPresentationLogicMock()
        let dataProvider = Self.makeDataProvider(
            results: [
                .success(makeData(monthStart: aprilStart, totalAmount: 120)),
                .failure(StubError.any)
            ]
        )
        let sut = AnalyticsInteractor(
            presenter: presenter,
            router: AnalyticsRoutingLogicMock(),
            repository: MainFlowDomainRepositoryProtocolMock(),
            dataProvider: dataProvider,
            observer: Self.makeObserver().observer,
            periodResolver: makePeriodResolver(),
            subscriptionAccessService: Self.makeSubscriptionAccessService(currentTier: "PREMIUM")
        )

        await sut.fetchData()

        await sut.handleTapRetry()

        let fetchCalls = dataProvider.fetchDataForReceivedInvocations
        XCTAssertEqual(fetchCalls, [aprilCurrentPeriod, aprilCurrentPeriod])
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.loadingState, .loaded)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.data?.totalAmount, 120)
    }
}

extension AnalyticsInteractorTests {
    func testHandleDidConfirmCategoryPeriodUpdatesLocalPeriodAndLoadsConfirmedRange() async {
        let presenter = AnalyticsPresentationLogicMock()
        let dataProvider = Self.makeDataProvider(
            results: [
                .success(makeData(monthStart: aprilStart, totalAmount: 120)),
                .success(makeData(monthStart: marchStart, totalAmount: 80))
            ]
        )
        let repository = MainFlowDomainRepositoryProtocolMock()
        let sut = AnalyticsInteractor(
            presenter: presenter,
            router: AnalyticsRoutingLogicMock(),
            repository: repository,
            dataProvider: dataProvider,
            observer: Self.makeObserver().observer,
            periodResolver: makePeriodResolver(),
            subscriptionAccessService: Self.makeSubscriptionAccessService(currentTier: "PREMIUM")
        )

        await sut.fetchData()
        await sut.handleDidConfirmCategoryPeriod(
            fromDate: marchCustomPeriod.from,
            to: marchCustomPeriod.to
        )

        let fetchCalls = dataProvider.fetchDataForReceivedInvocations
        let refreshMainFlowCalls = repository.refreshMainFlowCallsCount
        let refreshLoadedModulesCalls = repository.refreshLoadedPeriodDependentModulesCallsCount
        XCTAssertEqual(fetchCalls, [aprilCurrentPeriod, marchCustomPeriod])
        XCTAssertEqual(refreshMainFlowCalls, 0)
        XCTAssertEqual(refreshLoadedModulesCalls, 0)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.selectedPeriod, marchCustomPeriod)
        XCTAssertNil(presenter.presentFetchedDataReceivedInvocations.last?.selectedPreset)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.data?.monthStart, marchStart)
    }
}

extension AnalyticsInteractorTests {
    func testHandleDidConfirmCategoryPeriodWhenNewPeriodLoadFailsKeepsPreviousPeriodData() async {
        let presenter = AnalyticsPresentationLogicMock()
        let dataProvider = Self.makeDataProvider(
            results: [
                .success(makeData(monthStart: aprilStart, totalAmount: 120)),
                .failure(StubError.any)
            ]
        )
        let sut = AnalyticsInteractor(
            presenter: presenter,
            router: AnalyticsRoutingLogicMock(),
            repository: MainFlowDomainRepositoryProtocolMock(),
            dataProvider: dataProvider,
            observer: Self.makeObserver().observer,
            periodResolver: makePeriodResolver(),
            subscriptionAccessService: Self.makeSubscriptionAccessService(currentTier: "PREMIUM")
        )

        await sut.fetchData()
        await sut.handleDidConfirmCategoryPeriod(
            fromDate: marchCustomPeriod.from,
            to: marchCustomPeriod.to
        )

        let fetchCalls = dataProvider.fetchDataForReceivedInvocations
        XCTAssertEqual(fetchCalls, [aprilCurrentPeriod, marchCustomPeriod])
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.selectedPeriod, aprilCurrentPeriod)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.loadingState, .loaded)
        XCTAssertEqual(
            presenter.presentFetchedDataReceivedInvocations.last?.data,
            makeData(monthStart: aprilStart, totalAmount: 120)
        )
    }
}

extension AnalyticsInteractorTests {
    func testHandleTapCategoryRoutesToCategoryScreen() async {
        let router = AnalyticsRoutingLogicMock()
        let sut = AnalyticsInteractor(
            presenter: AnalyticsPresentationLogicMock(),
            router: router,
            repository: MainFlowDomainRepositoryProtocolMock(),
            dataProvider: Self.makeDataProvider(results: []),
            observer: Self.makeObserver().observer,
            periodResolver: makePeriodResolver(),
            subscriptionAccessService: Self.makeSubscriptionAccessService(currentTier: "PREMIUM")
        )

        await sut.fetchData()
        await sut.handleTapCategory(id: "food", name: "Food")

        XCTAssertEqual(router.openCategoryIdNamePeriodReceivedInvocations.count, 1)
        XCTAssertEqual(router.openCategoryIdNamePeriodReceivedInvocations.first?.id, "food")
        XCTAssertEqual(router.openCategoryIdNamePeriodReceivedInvocations.first?.name, "Food")
        XCTAssertEqual(router.openCategoryIdNamePeriodReceivedInvocations.first?.period, aprilCurrentPeriod)
    }
}

extension AnalyticsInteractorTests {
    func testHandleTapMonthFilterRoutesWithCurrentLocalPeriod() async {
        let router = AnalyticsRoutingLogicMock()
        let sut = AnalyticsInteractor(
            presenter: AnalyticsPresentationLogicMock(),
            router: router,
            repository: MainFlowDomainRepositoryProtocolMock(),
            dataProvider: Self.makeDataProvider(
                results: [
                    .success(makeData(monthStart: aprilStart, totalAmount: 120)),
                    .success(makeData(monthStart: marchStart, totalAmount: 80))
                ]
            ),
            observer: Self.makeObserver().observer,
            periodResolver: makePeriodResolver(),
            subscriptionAccessService: Self.makeSubscriptionAccessService(currentTier: "PREMIUM")
        )

        await sut.fetchData()
        await sut.handleDidConfirmCategoryPeriod(
            fromDate: marchCustomPeriod.from,
            to: marchCustomPeriod.to
        )
        await sut.handleTapMonthFilter()

        XCTAssertEqual(router.openPeriodPickerSelectedFromDateSelectedToDateOutputReceivedInvocations.map { MainSummaryPeriod(from: $0.selectedFromDate, to: $0.selectedToDate) }, [marchCustomPeriod])
    }

    func testHandleTapMonthFilterWithoutCustomDateAccessOpensSubscription() async {
        let router = AnalyticsRoutingLogicMock()
        let sut = AnalyticsInteractor(
            presenter: AnalyticsPresentationLogicMock(),
            router: router,
            repository: MainFlowDomainRepositoryProtocolMock(),
            dataProvider: Self.makeDataProvider(results: []),
            observer: Self.makeObserver().observer,
            periodResolver: makePeriodResolver(),
            subscriptionAccessService: Self.makeSubscriptionAccessService(
                currentTier: "PREMIUM",
                currentSnapshot: .init(
                    tier: .premium,
                    status: .active,
                    paidAccessUntil: nil,
                    capabilities: [.analytics],
                    aiRequestsLimit: 300,
                    aiRequestsRemaining: 300,
                    statusVersion: 42
                )
            )
        )

        await sut.fetchData()
        await sut.handleTapMonthFilter()

        XCTAssertTrue(router.openPeriodPickerSelectedFromDateSelectedToDateOutputReceivedInvocations.map { MainSummaryPeriod(from: $0.selectedFromDate, to: $0.selectedToDate) }.isEmpty)
        XCTAssertEqual(router.openSubscriptionCurrentTierOutputReceivedInvocations.last?.currentTier, .premium)
    }
}

extension AnalyticsInteractorTests {
    func testHandleSwipeToPreviousPeriodUsesCachedIntervalWithoutNetwork() async {
        let presenter = AnalyticsPresentationLogicMock()
        let dataProvider = Self.makeDataProvider(
            results: [.success(makeData(monthStart: aprilStart, totalAmount: 120))]
        )
        let analyticsIntervalRepository = makeIntervalRepository()
        await analyticsIntervalRepository.save(
            data: makeData(monthStart: marchStart, totalAmount: 80),
            for: marchMonthResolution
        )
        let sut = AnalyticsInteractor(
            presenter: presenter,
            router: AnalyticsRoutingLogicMock(),
            repository: MainFlowDomainRepositoryProtocolMock(),
            analyticsIntervalRepository: analyticsIntervalRepository,
            dataProvider: dataProvider,
            observer: Self.makeObserver().observer,
            periodResolver: makePeriodResolver(),
            subscriptionAccessService: Self.makeSubscriptionAccessService(currentTier: "PREMIUM")
        )

        await sut.fetchData()
        await sut.handleSwipeToPreviousPeriod()

        let awaitedValue1 = dataProvider.fetchDataForReceivedInvocations
        XCTAssertEqual(awaitedValue1, [aprilCurrentPeriod])
        XCTAssertFalse(
            presenter.presentFetchedDataReceivedInvocations.contains { presentedData in
                presentedData.isBodyLoading
            }
        )
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.selectedPeriod, marchMonthPeriod)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.selectedPreset, .month)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.data?.totalAmount, 80)
    }

    func testHandleSwipeToPreviousPeriodShowsLocalLoadingAndLoadsTargetInterval() async {
        let presenter = AnalyticsPresentationLogicMock()
        let dataProvider = Self.makeDataProvider(
            results: [
                .success(makeData(monthStart: aprilStart, totalAmount: 120)),
                .success(makeData(monthStart: marchStart, totalAmount: 80))
            ]
        )
        let sut = AnalyticsInteractor(
            presenter: presenter,
            router: AnalyticsRoutingLogicMock(),
            repository: MainFlowDomainRepositoryProtocolMock(),
            analyticsIntervalRepository: makeIntervalRepository(),
            dataProvider: dataProvider,
            observer: Self.makeObserver().observer,
            periodResolver: makePeriodResolver(),
            subscriptionAccessService: Self.makeSubscriptionAccessService(currentTier: "PREMIUM")
        )

        await sut.fetchData()
        await sut.handleSwipeToPreviousPeriod()

        let localLoadingState = presenter.presentFetchedDataReceivedInvocations.last {
            $0.isBodyLoading && $0.selectedPeriod == marchMonthPeriod
        }

        let awaitedValue2 = dataProvider.fetchDataForReceivedInvocations
        XCTAssertEqual(
            awaitedValue2,
            [aprilCurrentPeriod, marchMonthPeriod]
        )
        XCTAssertEqual(localLoadingState?.selectedPreset, .month)
        XCTAssertEqual(localLoadingState?.data?.totalAmount, 120)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.selectedPeriod, marchMonthPeriod)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.data?.totalAmount, 80)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.loadingState, .loaded)
    }

    func testHandleSwipeToPreviousPeriodOnFailureReturnsPreviousLoadedContent() async {
        let presenter = AnalyticsPresentationLogicMock()
        let dataProvider = Self.makeDataProvider(
            results: [
                .success(makeData(monthStart: aprilStart, totalAmount: 120)),
                .failure(StubError.any)
            ]
        )
        let sut = AnalyticsInteractor(
            presenter: presenter,
            router: AnalyticsRoutingLogicMock(),
            repository: MainFlowDomainRepositoryProtocolMock(),
            analyticsIntervalRepository: makeIntervalRepository(),
            dataProvider: dataProvider,
            observer: Self.makeObserver().observer,
            periodResolver: makePeriodResolver(),
            subscriptionAccessService: Self.makeSubscriptionAccessService(currentTier: "PREMIUM")
        )

        await sut.fetchData()
        await sut.handleSwipeToPreviousPeriod()

        let awaitedValue3 = dataProvider.fetchDataForReceivedInvocations
        XCTAssertEqual(
            awaitedValue3,
            [aprilCurrentPeriod, marchMonthPeriod]
        )
        XCTAssertTrue(
            presenter.presentFetchedDataReceivedInvocations.contains {
                $0.isBodyLoading && $0.selectedPeriod == marchMonthPeriod
            }
        )
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.selectedPeriod, aprilCurrentPeriod)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.selectedPreset, .month)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.data?.totalAmount, 120)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.loadingState, .loaded)
        XCTAssertFalse(presenter.presentFetchedDataReceivedInvocations.last?.isBodyLoading ?? true)
    }

    func testHandleSwipeToPreviousPeriodWithEmptyMonthOpensItAndAllowsFurtherSwipe() async {
        let presenter = AnalyticsPresentationLogicMock()
        let februaryMonthPeriod = makePeriodResolver().previousPeriod(
            for: marchMonthResolution
        ).period
        let dataProvider = Self.makeDataProvider(
            results: [
                .success(makeData(monthStart: aprilStart, totalAmount: 120)),
                .success(
                    AnalyticsDataModel(
                        monthStart: marchStart,
                        totalAmount: 0,
                        currency: "USD",
                        categories: []
                    )
                ),
                .success(
                    makeData(
                        monthStart: februaryMonthPeriod.from,
                        totalAmount: 80
                    )
                )
            ]
        )
        let sut = AnalyticsInteractor(
            presenter: presenter,
            router: AnalyticsRoutingLogicMock(),
            repository: MainFlowDomainRepositoryProtocolMock(),
            analyticsIntervalRepository: makeIntervalRepository(),
            dataProvider: dataProvider,
            observer: Self.makeObserver().observer,
            periodResolver: makePeriodResolver(),
            subscriptionAccessService: Self.makeSubscriptionAccessService(currentTier: "PREMIUM")
        )

        await sut.fetchData()
        await sut.handleSwipeToPreviousPeriod()
        await sut.handleSwipeToPreviousPeriod()

        let awaitedValue4 = dataProvider.fetchDataForReceivedInvocations
        XCTAssertEqual(
            awaitedValue4,
            [aprilCurrentPeriod, marchMonthPeriod, februaryMonthPeriod]
        )
        XCTAssertTrue(
            presenter.presentFetchedDataReceivedInvocations.contains {
                $0.selectedPeriod == marchMonthPeriod
                    && $0.selectedPreset == .month
                    && $0.data?.isEmpty == true
                    && $0.loadingState == .loaded
            }
        )
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.selectedPeriod, februaryMonthPeriod)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.selectedPreset, .month)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.data?.totalAmount, 80)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.loadingState, .loaded)
        XCTAssertFalse(presenter.presentFetchedDataReceivedInvocations.last?.isBodyLoading ?? true)
    }

    func testHandleSwipeToPreviousAndNextPeriodDoNothingForCustomRange() async {
        let presenter = AnalyticsPresentationLogicMock()
        let dataProvider = Self.makeDataProvider(
            results: [
                .success(makeData(monthStart: aprilStart, totalAmount: 120)),
                .success(makeData(monthStart: marchStart, totalAmount: 80))
            ]
        )
        let sut = AnalyticsInteractor(
            presenter: presenter,
            router: AnalyticsRoutingLogicMock(),
            repository: MainFlowDomainRepositoryProtocolMock(),
            analyticsIntervalRepository: makeIntervalRepository(),
            dataProvider: dataProvider,
            observer: Self.makeObserver().observer,
            periodResolver: makePeriodResolver(),
            subscriptionAccessService: Self.makeSubscriptionAccessService(currentTier: "PREMIUM")
        )

        await sut.fetchData()
        await sut.handleDidConfirmCategoryPeriod(
            fromDate: marchCustomPeriod.from,
            to: marchCustomPeriod.to
        )
        await sut.handleSwipeToPreviousPeriod()
        await sut.handleSwipeToNextPeriod()

        let awaitedValue5 = dataProvider.fetchDataForReceivedInvocations
        XCTAssertEqual(
            awaitedValue5,
            [aprilCurrentPeriod, marchCustomPeriod]
        )
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.selectedPeriod, marchCustomPeriod)
        XCTAssertNil(presenter.presentFetchedDataReceivedInvocations.last?.selectedPreset)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.data?.totalAmount, 80)
    }

    func testHandleSelectPresetCacheMissSavesFetchedIntervalForLaterReuse() async {
        let presenter = AnalyticsPresentationLogicMock()
        let dataProvider = Self.makeDataProvider(
            results: [
                .success(makeData(monthStart: aprilStart, totalAmount: 120)),
                .success(makeData(monthStart: aprilStart, totalAmount: 80))
            ]
        )
        let analyticsIntervalRepository = makeIntervalRepository()
        let sut = AnalyticsInteractor(
            presenter: presenter,
            router: AnalyticsRoutingLogicMock(),
            repository: MainFlowDomainRepositoryProtocolMock(),
            analyticsIntervalRepository: analyticsIntervalRepository,
            dataProvider: dataProvider,
            observer: Self.makeObserver().observer,
            periodResolver: makePeriodResolver(),
            subscriptionAccessService: Self.makeSubscriptionAccessService(currentTier: "PREMIUM")
        )

        await sut.fetchData()
        await sut.handleSelectPreset(.week)
        await sut.handleSelectPreset(.month)
        await sut.handleSelectPreset(.week)

        let awaitedValue6 = dataProvider.fetchDataForReceivedInvocations
        XCTAssertEqual(
            awaitedValue6,
            [aprilCurrentPeriod, aprilCurrentWeekPeriod]
        )
        let awaitedValue7 = await analyticsIntervalRepository.cachedData(for: aprilCurrentWeekResolution)
        XCTAssertEqual(
            awaitedValue7,
            makeData(monthStart: aprilStart, totalAmount: 80)
        )
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.selectedPreset, .week)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.data?.totalAmount, 80)
    }

    func testObserverInvalidationRefreshesCurrentLocalPeriod() async {
        let presenter = AnalyticsPresentationLogicMock()
        let dataProvider = Self.makeDataProvider(
            results: [
                .success(makeData(monthStart: aprilStart, totalAmount: 140))
            ]
        )
        let (observer, publishOverview) = Self.makeObserver()
        let analyticsIntervalRepository = makeIntervalRepository()
        await analyticsIntervalRepository.save(
            data: makeData(monthStart: aprilStart, totalAmount: 120),
            for: aprilCurrentResolution
        )
        let sut = AnalyticsInteractor(
            presenter: presenter,
            router: AnalyticsRoutingLogicMock(),
            repository: MainFlowDomainRepositoryProtocolMock(),
            analyticsIntervalRepository: analyticsIntervalRepository,
            dataProvider: dataProvider,
            observer: observer,
            periodResolver: makePeriodResolver(),
            subscriptionAccessService: Self.makeSubscriptionAccessService(currentTier: "PREMIUM")
        )

        let refreshedDataPresented = presentationExpectation(on: presenter) { data in
            data.data?.totalAmount == 140
        }

        await sut.fetchData()
        publishOverview()

        await fulfillment(of: [refreshedDataPresented], timeout: 1)

        let awaitedValue8 = dataProvider.fetchDataForReceivedInvocations
        XCTAssertEqual(awaitedValue8, [aprilCurrentPeriod])
        let awaitedValue9 = await analyticsIntervalRepository.cachedData(for: aprilCurrentResolution)?.totalAmount
        XCTAssertEqual(
            awaitedValue9,
            140
        )
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.data?.totalAmount, 140)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.selectedPeriod, aprilCurrentPeriod)
    }

    func testHandleDidConfirmCategoryPeriodUsesCachedCustomIntervalWithoutNetwork() async {
        let presenter = AnalyticsPresentationLogicMock()
        let dataProvider = Self.makeDataProvider(results: [])
        let analyticsIntervalRepository = makeIntervalRepository()
        await analyticsIntervalRepository.save(
            data: makeData(monthStart: aprilStart, totalAmount: 120),
            for: aprilCurrentResolution
        )
        await analyticsIntervalRepository.save(
            data: makeData(monthStart: marchStart, totalAmount: 80),
            for: marchCustomResolution
        )
        let sut = AnalyticsInteractor(
            presenter: presenter,
            router: AnalyticsRoutingLogicMock(),
            repository: MainFlowDomainRepositoryProtocolMock(),
            analyticsIntervalRepository: analyticsIntervalRepository,
            dataProvider: dataProvider,
            observer: Self.makeObserver().observer,
            periodResolver: makePeriodResolver(),
            subscriptionAccessService: Self.makeSubscriptionAccessService(currentTier: "PREMIUM")
        )

        await sut.fetchData()
        await sut.handleDidConfirmCategoryPeriod(
            fromDate: marchCustomPeriod.from,
            to: marchCustomPeriod.to
        )

        let awaitedValue10 = dataProvider.fetchDataForReceivedInvocations
        XCTAssertEqual(awaitedValue10, [])
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.selectedPeriod, marchCustomPeriod)
        XCTAssertNil(presenter.presentFetchedDataReceivedInvocations.last?.selectedPreset)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.data?.totalAmount, 80)
    }

    func testSubscriptionAccessDowngradeLocksScreenAndStopsOverviewRefresh() async {
        let presenter = AnalyticsPresentationLogicMock()
        let dataProvider = Self.makeDataProvider(
            results: [.success(makeData(monthStart: aprilStart, totalAmount: 120))]
        )
        let (observer, publishOverview) = Self.makeObserver()
        let notificationCenter = NotificationCenter()
        let sut = AnalyticsInteractor(
            presenter: presenter,
            router: AnalyticsRoutingLogicMock(),
            repository: MainFlowDomainRepositoryProtocolMock(),
            dataProvider: dataProvider,
            observer: observer,
            periodResolver: makePeriodResolver(),
            subscriptionAccessService: Self.makeSubscriptionAccessService(currentTier: "PREMIUM"),
            notificationCenter: notificationCenter
        )

        await sut.fetchData()
        let fetchCallsBeforeDowngrade = dataProvider.fetchDataForReceivedInvocations
        let fetchCallsCountBeforeDowngrade = fetchCallsBeforeDowngrade.count
        let screenLocked = presentationExpectation(on: presenter) { data in
            data.isLocked
        }

        notificationCenter.post(
            name: .subscriptionAccessDidChange,
            object: makeSubscriptionSnapshot(tier: .regular)
        )
        await fulfillment(of: [screenLocked], timeout: 1)

        let overviewRefreshed = presentationExpectation(on: presenter) { data in
            !data.isLocked || data.data != nil
        }
        overviewRefreshed.isInverted = true

        publishOverview()
        await fulfillment(of: [overviewRefreshed], timeout: 0.2)

        let fetchCallsAfterDowngrade = dataProvider.fetchDataForReceivedInvocations
        let fetchCallsCountAfterDowngrade = fetchCallsAfterDowngrade.count
        XCTAssertEqual(fetchCallsCountAfterDowngrade, fetchCallsCountBeforeDowngrade)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.isLocked, true)
        XCTAssertNil(presenter.presentFetchedDataReceivedInvocations.last?.data)
    }

    func testUsageOnlyNotificationDoesNotLockScreenWhenSemanticStatusMatches() async {
        let presenter = AnalyticsPresentationLogicMock()
        let dataProvider = Self.makeDataProvider(
            results: [.success(makeData(monthStart: aprilStart, totalAmount: 120))]
        )
        let notificationCenter = NotificationCenter()
        let sut = AnalyticsInteractor(
            presenter: presenter,
            router: AnalyticsRoutingLogicMock(),
            repository: MainFlowDomainRepositoryProtocolMock(),
            dataProvider: dataProvider,
            observer: Self.makeObserver().observer,
            periodResolver: makePeriodResolver(),
            subscriptionAccessService: Self.makeSubscriptionAccessService(currentTier: "PREMIUM"),
            notificationCenter: notificationCenter
        )

        await sut.fetchData()
        let screenLocked = presentationExpectation(on: presenter) { data in
            data.isLocked
        }
        screenLocked.isInverted = true

        notificationCenter.post(
            name: .subscriptionAccessDidChange,
            object: makeSubscriptionSnapshot(tier: .regular, aiRequestsRemaining: 271),
            userInfo: [
                SubscriptionAccessDidChangeNotificationUserInfoKey.previousSnapshot:
                    makeSubscriptionSnapshot(tier: .regular, aiRequestsRemaining: 272)
            ]
        )

        await fulfillment(of: [screenLocked], timeout: 0.2)

        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.isLocked, false)
        let awaitedValue11 = dataProvider.fetchDataForReceivedInvocations
        XCTAssertEqual(awaitedValue11, [aprilCurrentPeriod])
    }

    func testHandleSubscriptionDidSyncKeepsSelectedLocalPeriodAndLoadsAnalytics() async {
        let presenter = AnalyticsPresentationLogicMock()
        let dataProvider = Self.makeDataProvider(
            results: [
                .success(makeData(monthStart: aprilStart, totalAmount: 120)),
                .success(makeData(monthStart: marchStart, totalAmount: 90)),
                .success(makeData(monthStart: marchStart, totalAmount: 130))
            ]
        )
        let sut = AnalyticsInteractor(
            presenter: presenter,
            router: AnalyticsRoutingLogicMock(),
            repository: MainFlowDomainRepositoryProtocolMock(),
            dataProvider: dataProvider,
            observer: Self.makeObserver().observer,
            periodResolver: makePeriodResolver(),
            subscriptionAccessService: Self.makeSubscriptionAccessService(currentTier: "PREMIUM", refreshedTier: "PREMIUM")
        )

        await sut.fetchData()
        await sut.handleDidConfirmCategoryPeriod(
            fromDate: marchCustomPeriod.from,
            to: marchCustomPeriod.to
        )
        await sut.handleSubscriptionDidSync()

        let fetchCalls = dataProvider.fetchDataForReceivedInvocations

        XCTAssertEqual(fetchCalls, [aprilCurrentPeriod, marchCustomPeriod, marchCustomPeriod])
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.selectedPeriod, marchCustomPeriod)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.data?.totalAmount, 130)
    }

    func testFetchDataWithRegularTierShowsLockedStateWithoutLoadingData() async {
        let presenter = AnalyticsPresentationLogicMock()
        let (observer, _) = Self.makeObserver()
        let dataProvider = Self.makeDataProvider(results: [])
        let sut = AnalyticsInteractor(
            presenter: presenter,
            router: AnalyticsRoutingLogicMock(),
            repository: MainFlowDomainRepositoryProtocolMock(),
            dataProvider: dataProvider,
            observer: observer,
            periodResolver: makePeriodResolver(),
            subscriptionAccessService: Self.makeSubscriptionAccessService(currentTier: "REGULAR")
        )

        await sut.fetchData()
        let recordedFetchCalls = dataProvider.fetchDataForReceivedInvocations

        XCTAssertEqual(recordedFetchCalls, [])
        XCTAssertEqual(observer.subscribeOverviewCallsCount, 0)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.isLocked, true)
    }

    func testHandleTapSubscribeOpensSubscription() async {
        let router = AnalyticsRoutingLogicMock()
        let sut = AnalyticsInteractor(
            presenter: AnalyticsPresentationLogicMock(),
            router: router,
            repository: MainFlowDomainRepositoryProtocolMock(),
            dataProvider: Self.makeDataProvider(results: []),
            observer: Self.makeObserver().observer,
            periodResolver: makePeriodResolver(),
            subscriptionAccessService: Self.makeSubscriptionAccessService(currentTier: "REGULAR")
        )

        await sut.fetchData()
        await sut.handleTapSubscribe()

        XCTAssertEqual(router.openSubscriptionCurrentTierOutputReceivedInvocations.last?.currentTier, .regular)
    }

    func testHandleSubscriptionDidSyncRefreshesTierAndLoadsAnalyticsWhenUnlocked() async {
        let presenter = AnalyticsPresentationLogicMock()
        let dataProvider = Self.makeDataProvider(
            results: [.success(makeData(monthStart: aprilStart, totalAmount: 220))]
        )
        let subscriptionAccessService = Self.makeSubscriptionAccessService(
            currentTier: "REGULAR",
            refreshedTier: "PREMIUM"
        )
        let sut = AnalyticsInteractor(
            presenter: presenter,
            router: AnalyticsRoutingLogicMock(),
            repository: MainFlowDomainRepositoryProtocolMock(),
            dataProvider: dataProvider,
            observer: Self.makeObserver().observer,
            periodResolver: makePeriodResolver(),
            subscriptionAccessService: subscriptionAccessService
        )

        await sut.fetchData()
        await sut.handleSubscriptionDidSync()
        let refreshCallsCount = subscriptionAccessService.refreshCurrentSubscriptionSnapshotCallsCount + subscriptionAccessService.refreshCurrentTierStateCallsCount + subscriptionAccessService.refreshCurrentTierSourceStateCallsCount
        let recordedFetchCalls = dataProvider.fetchDataForReceivedInvocations

        XCTAssertEqual(refreshCallsCount, 1)
        XCTAssertEqual(recordedFetchCalls, [aprilCurrentPeriod])
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.isLocked, false)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.data?.totalAmount, 220)
    }
}

private extension AnalyticsInteractorTests {
    enum StubError: LocalizedError {
        case any

        var errorDescription: String? {
            "Any error"
        }
    }

    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar
    }

    var aprilStart: Date {
        makeDate(year: 2026, month: 4, day: 1)
    }

    var aprilCurrentPeriod: MainSummaryPeriod {
        .init(
            from: aprilStart,
            to: makeDate(year: 2026, month: 4, day: 6)
        )
    }

    var aprilCurrentResolution: AnalyticsPeriodResolution {
        .init(
            period: aprilCurrentPeriod,
            preset: .month
        )
    }

    var aprilCurrentWeekPeriod: MainSummaryPeriod {
        makePeriodResolver().resolveCurrentPeriod(for: .week).period
    }

    var aprilCurrentWeekResolution: AnalyticsPeriodResolution {
        .init(
            period: aprilCurrentWeekPeriod,
            preset: .week
        )
    }

    var aprilCustomPeriod: MainSummaryPeriod {
        .init(
            from: makeDate(year: 2026, month: 4, day: 2),
            to: makeDate(year: 2026, month: 4, day: 6)
        )
    }

    var marchStart: Date {
        makeDate(year: 2026, month: 3, day: 1)
    }

    var marchCustomPeriod: MainSummaryPeriod {
        .init(
            from: makeDate(year: 2026, month: 3, day: 18),
            to: marchEnd
        )
    }

    var marchCustomResolution: AnalyticsPeriodResolution {
        .init(
            period: marchCustomPeriod,
            preset: nil
        )
    }

    var marchMonthPeriod: MainSummaryPeriod {
        .init(
            from: marchStart,
            to: marchEnd
        )
    }

    var marchMonthResolution: AnalyticsPeriodResolution {
        .init(
            period: marchMonthPeriod,
            preset: .month
        )
    }

    var marchEnd: Date {
        calendar.dateInterval(of: .month, for: marchStart)?.end.addingTimeInterval(-1) ?? .distantPast
    }

    func makePeriodResolver(now: Date? = nil) -> AnalyticsPeriodResolving {
        let currentDate = now ?? aprilCurrentPeriod.to
        return AnalyticsPeriodResolver(
            calendar: calendar,
            now: { currentDate }
        )
    }

    func makeDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0,
        minute: Int = 0,
        second: Int = 0
    ) -> Date {
        calendar.date(
            from: DateComponents(
                timeZone: calendar.timeZone,
                year: year,
                month: month,
                day: day,
                hour: hour,
                minute: minute,
                second: second
            )
        ) ?? .distantPast
    }

    func makeData(
        monthStart: Date,
        totalAmount: Double
    ) -> AnalyticsDataModel {
        AnalyticsDataModel(
            monthStart: monthStart,
            totalAmount: totalAmount,
            currency: "USD",
            categories: [
                .init(
                    id: "food",
                    name: "Food",
                    icon: "🍔",
                    colorValue: "light_green",
                    amount: totalAmount,
                    currency: "USD",
                    share: 1,
                    isInteractive: true
                )
            ]
        )
    }

    func makeIntervalRepository() -> AnalyticsIntervalRepository {
        AnalyticsIntervalRepository(calendar: calendar)
    }

    func makeSubscriptionSnapshot(
        tier: SubscriptionTier,
        aiRequestsRemaining: Int? = nil
    ) -> SubscriptionAccessSnapshot {
        let capabilities: [SubscriptionCapability] = switch tier {
        case .premium:
            [.analytics, .customDateRange, .aiInput]
        case .regular:
            []
        }

        return SubscriptionAccessSnapshot(
            tier: tier,
            status: .active,
            paidAccessUntil: nil,
            capabilities: capabilities,
            aiRequestsLimit: capabilities.isEmpty ? 0 : 300,
            aiRequestsRemaining: aiRequestsRemaining ?? (capabilities.isEmpty ? 0 : 300),
            statusVersion: 42
        )
    }

    func presentationExpectation(
        on presenter: AnalyticsPresentationLogicMock,
        where predicate: @escaping (AnalyticsFetchData) -> Bool
    ) -> XCTestExpectation {
        let expectation = expectation(description: "Presenter received expected data")
        expectation.assertForOverFulfill = false
        presenter.presentFetchedDataClosure = { data in
            guard predicate(data) else {
                return
            }

            expectation.fulfill()
        }
        return expectation
    }
}

private extension AnalyticsInteractorTests {
    nonisolated static func makeObserver() -> (observer: MainFlowDomainObserverProtocolMock, publishOverview: () -> Void) {
        var continuation: AsyncStream<MainFlowOverviewSnapshot>.Continuation?
        let observer = MainFlowDomainObserverProtocolMock()
        observer.subscribeOverviewClosure = {
            AsyncStream(bufferingPolicy: .unbounded) {
                continuation = $0
                $0.yield(.init())
            }
        }
        observer.currentOverviewSnapshotReturnValue = .init()
        observer.currentCategoriesSnapshotReturnValue = .init()
        return (observer, { continuation?.yield(.init()) })
    }

    nonisolated static func makeDataProvider(results: [Result<AnalyticsDataModel, Error>]) -> AnalyticsDataProvidingMock {
        let dataProvider = AnalyticsDataProvidingMock()
        dataProvider.fetchDataForClosure = { [unowned dataProvider] period in
            guard !results.isEmpty else {
                return AnalyticsDataModel(monthStart: period.from, totalAmount: 0, currency: "USD", categories: [])
            }

            let index = min(dataProvider.fetchDataForCallsCount - 1, results.count - 1)
            return try results[index].get()
        }
        return dataProvider
    }

    nonisolated static func makeSubscriptionAccessService(
        currentTier: String = "REGULAR",
        refreshedTier: String? = nil,
        currentTierState: SubscriptionTierState? = nil,
        refreshedTierState: SubscriptionTierState? = nil,
        currentSnapshot: SubscriptionAccessSnapshot? = nil,
        refreshedSnapshot: SubscriptionAccessSnapshot? = nil
    ) -> SubscriptionAccessServicingMock {
        let currentState = currentTierState ?? .resolved(makeTier(from: currentTier))
        let refreshedState = refreshedTierState ?? .resolved(makeTier(from: refreshedTier ?? currentTier))
        let subscriptionAccessService = SubscriptionAccessServicingMock()
        subscriptionAccessService.currentTierStateReturnValue = currentState
        subscriptionAccessService.refreshCurrentTierStateReturnValue = refreshedState
        switch refreshedState {
        case .resolved(let tier):
            subscriptionAccessService.refreshCurrentTierSourceStateReturnValue = .network(tier)
        case .unavailable:
            subscriptionAccessService.refreshCurrentTierSourceStateReturnValue = .unavailable
        }
        subscriptionAccessService.currentSubscriptionSnapshotReturnValue = currentSnapshot ?? makeSnapshot(from: currentState)
        subscriptionAccessService.refreshCurrentSubscriptionSnapshotReturnValue = refreshedSnapshot ?? makeSnapshot(from: refreshedState)
        return subscriptionAccessService
    }

    nonisolated static func makeSnapshot(from tierState: SubscriptionTierState) -> SubscriptionAccessSnapshot? {
        guard case .resolved(let tier) = tierState else {
            return nil
        }

        return SubscriptionAccessSnapshotFixtures.makeSnapshot(tierName: tier == .regular ? "REGULAR" : "PREMIUM")
    }

    nonisolated static func makeTier(from rawTier: String) -> SubscriptionTier {
        rawTier == "REGULAR" ? .regular : .premium
    }
}
