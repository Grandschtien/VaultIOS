import XCTest
@testable import Vault

@MainActor
final class AnalyticsInteractorTests: XCTestCase {
    func testFetchDataLoadsCurrentAnalyticsPeriod() async {
        let presenter = AnalyticsPresenterSpy()
        let dataProvider = AnalyticsDataProviderStub(
            results: [.success(makeData(monthStart: aprilStart, totalAmount: 120))]
        )
        let summaryPeriodProvider = MainSummaryPeriodServiceStub(period: aprilCurrentPeriod)
        let sut = AnalyticsInteractor(
            presenter: presenter,
            router: AnalyticsRouterSpy(),
            dataProvider: dataProvider,
            observer: AnalyticsObserverStub(),
            summaryPeriodProvider: summaryPeriodProvider
        )

        await sut.fetchData()
        await waitForUpdates()

        let fetchCalls = await dataProvider.recordedFetchCalls()
        XCTAssertEqual(fetchCalls, [aprilCurrentPeriod])
        XCTAssertEqual(presenter.presentedData.first?.loadingState, .loading)
        XCTAssertEqual(presenter.presentedData.last?.loadingState, .loaded)
        XCTAssertEqual(presenter.presentedData.last?.data?.totalAmount, 120)
    }
}

extension AnalyticsInteractorTests {
    func testHandleTapRetryKeepsLoadedDataWhenRefreshFails() async {
        let presenter = AnalyticsPresenterSpy()
        let dataProvider = AnalyticsDataProviderStub(
            results: [
                .success(makeData(monthStart: aprilStart, totalAmount: 120)),
                .failure(StubError.any)
            ]
        )
        let summaryPeriodProvider = MainSummaryPeriodServiceStub(period: aprilCurrentPeriod)
        let sut = AnalyticsInteractor(
            presenter: presenter,
            router: AnalyticsRouterSpy(),
            dataProvider: dataProvider,
            observer: AnalyticsObserverStub(),
            summaryPeriodProvider: summaryPeriodProvider
        )

        await sut.fetchData()
        await waitForUpdates()

        await sut.handleTapRetry()
        await waitForUpdates()

        let fetchCalls = await dataProvider.recordedFetchCalls()
        XCTAssertEqual(fetchCalls, [aprilCurrentPeriod, aprilCurrentPeriod])
        XCTAssertEqual(presenter.presentedData.last?.loadingState, .loaded)
        XCTAssertEqual(presenter.presentedData.last?.data?.totalAmount, 120)
    }
}

extension AnalyticsInteractorTests {
    func testHandleDidConfirmCategoryPeriodUpdatesSharedProviderAndLoadsConfirmedRange() async {
        let presenter = AnalyticsPresenterSpy()
        let dataProvider = AnalyticsDataProviderStub(
            results: [
                .success(makeData(monthStart: aprilStart, totalAmount: 120)),
                .success(makeData(monthStart: marchStart, totalAmount: 80))
            ]
        )
        let summaryPeriodProvider = MainSummaryPeriodServiceStub(period: aprilCurrentPeriod)
        let sut = AnalyticsInteractor(
            presenter: presenter,
            router: AnalyticsRouterSpy(),
            dataProvider: dataProvider,
            observer: AnalyticsObserverStub(),
            summaryPeriodProvider: summaryPeriodProvider
        )

        await sut.fetchData()
        await waitForUpdates()
        await sut.handleDidConfirmCategoryPeriod(
            fromDate: marchCustomPeriod.from,
            to: marchCustomPeriod.to
        )
        await waitForUpdates()

        let fetchCalls = await dataProvider.recordedFetchCalls()
        XCTAssertEqual(fetchCalls, [aprilCurrentPeriod, marchCustomPeriod])
        XCTAssertEqual(summaryPeriodProvider.currentMonthPeriod(), marchCustomPeriod)
        XCTAssertEqual(presenter.presentedData.last?.data?.monthStart, marchStart)
    }
}

extension AnalyticsInteractorTests {
    func testHandleDidConfirmCategoryPeriodShowsErrorWhenNewPeriodLoadFails() async {
        let presenter = AnalyticsPresenterSpy()
        let dataProvider = AnalyticsDataProviderStub(
            results: [
                .success(makeData(monthStart: aprilStart, totalAmount: 120)),
                .failure(StubError.any)
            ]
        )
        let summaryPeriodProvider = MainSummaryPeriodServiceStub(period: aprilCurrentPeriod)
        let sut = AnalyticsInteractor(
            presenter: presenter,
            router: AnalyticsRouterSpy(),
            dataProvider: dataProvider,
            observer: AnalyticsObserverStub(),
            summaryPeriodProvider: summaryPeriodProvider
        )

        await sut.fetchData()
        await waitForUpdates()
        await sut.handleDidConfirmCategoryPeriod(
            fromDate: marchCustomPeriod.from,
            to: marchCustomPeriod.to
        )
        await waitForUpdates()

        let fetchCalls = await dataProvider.recordedFetchCalls()
        XCTAssertEqual(fetchCalls, [aprilCurrentPeriod, marchCustomPeriod])
        XCTAssertEqual(summaryPeriodProvider.currentMonthPeriod(), marchCustomPeriod)
        XCTAssertEqual(presenter.presentedData.last?.loadingState, .failed(.undelinedError(description: StubError.any.localizedDescription)))
        XCTAssertNil(presenter.presentedData.last?.data)
    }
}

extension AnalyticsInteractorTests {
    func testHandleTapCategoryRoutesToCategoryScreen() async {
        let router = AnalyticsRouterSpy()
        let sut = AnalyticsInteractor(
            presenter: AnalyticsPresenterSpy(),
            router: router,
            dataProvider: AnalyticsDataProviderStub(results: []),
            observer: AnalyticsObserverStub(),
            summaryPeriodProvider: MainSummaryPeriodServiceStub(period: aprilCurrentPeriod)
        )

        await sut.handleTapCategory(id: "food", name: "Food")

        XCTAssertEqual(router.openCategoryCalls.count, 1)
        XCTAssertEqual(router.openCategoryCalls.first?.0, "food")
        XCTAssertEqual(router.openCategoryCalls.first?.1, "Food")
    }
}

extension AnalyticsInteractorTests {
    func testHandleTapMonthFilterRoutesWithCurrentSharedPeriod() async {
        let router = AnalyticsRouterSpy()
        let currentPeriod = MainSummaryPeriod(
            from: makeDate(year: 2026, month: 4, day: 3),
            to: makeDate(year: 2026, month: 4, day: 6)
        )
        let sut = AnalyticsInteractor(
            presenter: AnalyticsPresenterSpy(),
            router: router,
            dataProvider: AnalyticsDataProviderStub(results: []),
            observer: AnalyticsObserverStub(),
            summaryPeriodProvider: MainSummaryPeriodServiceStub(period: currentPeriod)
        )

        await sut.handleTapMonthFilter()

        XCTAssertEqual(router.openPeriodPickerCalls, [currentPeriod])
    }
}

extension AnalyticsInteractorTests {
    func testObserverInvalidationRefreshesCurrentSharedPeriod() async {
        let presenter = AnalyticsPresenterSpy()
        let dataProvider = AnalyticsDataProviderStub(
            results: [
                .success(makeData(monthStart: aprilStart, totalAmount: 120)),
                .success(makeData(monthStart: marchStart, totalAmount: 80)),
                .success(makeData(monthStart: aprilStart, totalAmount: 130)),
                .success(makeData(monthStart: aprilStart, totalAmount: 140))
            ]
        )
        let observer = AnalyticsObserverStub()
        let summaryPeriodProvider = MainSummaryPeriodServiceStub(period: aprilCurrentPeriod)
        let sut = AnalyticsInteractor(
            presenter: presenter,
            router: AnalyticsRouterSpy(),
            dataProvider: dataProvider,
            observer: observer,
            summaryPeriodProvider: summaryPeriodProvider
        )

        await sut.fetchData()
        await waitForUpdates()
        await sut.handleDidConfirmCategoryPeriod(
            fromDate: marchCustomPeriod.from,
            to: marchCustomPeriod.to
        )
        await waitForUpdates()
        await sut.handleDidConfirmCategoryPeriod(
            fromDate: aprilCustomPeriod.from,
            to: aprilCustomPeriod.to
        )
        await waitForUpdates()
        observer.publishOverview()
        await waitForUpdates()

        let fetchCalls = await dataProvider.recordedFetchCalls()
        XCTAssertEqual(
            fetchCalls,
            [aprilCurrentPeriod, marchCustomPeriod, aprilCustomPeriod, aprilCustomPeriod]
        )
        XCTAssertEqual(summaryPeriodProvider.currentMonthPeriod(), aprilCustomPeriod)
        XCTAssertEqual(presenter.presentedData.last?.data?.totalAmount, 140)
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

    var marchEnd: Date {
        calendar.dateInterval(of: .month, for: marchStart)?.end.addingTimeInterval(-1) ?? .distantPast
    }

    func makeDate(
        year: Int,
        month: Int,
        day: Int
    ) -> Date {
        calendar.date(
            from: DateComponents(
                timeZone: calendar.timeZone,
                year: year,
                month: month,
                day: day
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

    func waitForUpdates() async {
        await Task.yield()
        await Task.yield()
        await Task.yield()
    }
}

@MainActor
private final class AnalyticsPresenterSpy: AnalyticsPresentationLogic {
    private(set) var presentedData: [AnalyticsFetchData] = []

    func presentFetchedData(_ data: AnalyticsFetchData) {
        presentedData.append(data)
    }
}

@MainActor
private final class AnalyticsRouterSpy: AnalyticsRoutingLogic {
    private(set) var openCategoryCalls: [(String, String)] = []
    private(set) var openPeriodPickerCalls: [MainSummaryPeriod] = []

    func openCategory(id: String, name: String) {
        openCategoryCalls.append((id, name))
    }

    func openPeriodPicker(
        selectedFromDate: Date,
        selectedToDate: Date,
        output: CategoryPeriodPickerOutput
    ) {
        openPeriodPickerCalls.append(
            .init(
                from: selectedFromDate,
                to: selectedToDate
            )
        )
    }
}

private final class AnalyticsObserverStub: MainFlowDomainObserverProtocol, @unchecked Sendable {
    private var continuation: AsyncStream<MainFlowOverviewSnapshot>.Continuation?

    func subscribeOverview() -> AsyncStream<MainFlowOverviewSnapshot> {
        AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            self.continuation = continuation
            continuation.yield(.init())
        }
    }

    func subscribeCategories() -> AsyncStream<MainFlowCategoriesSnapshot> {
        AsyncStream { $0.finish() }
    }

    func subscribeCategory(id: String) -> AsyncStream<MainFlowCategorySnapshot> {
        AsyncStream { $0.finish() }
    }

    func subscribeExpensesList() -> AsyncStream<MainFlowExpensesListSnapshot> {
        AsyncStream { $0.finish() }
    }

    func currentOverviewSnapshot() -> MainFlowOverviewSnapshot {
        .init()
    }

    func currentCategoriesSnapshot() -> MainFlowCategoriesSnapshot {
        .init()
    }

    func currentCategorySnapshot(id: String) -> MainFlowCategorySnapshot {
        .init(categoryID: id)
    }

    func currentExpensesListSnapshot() -> MainFlowExpensesListSnapshot {
        .init()
    }

    func publishAll(from store: MainFlowDomainStoreProtocol) {}

    func finishAll() {
        continuation?.finish()
    }

    func publishOverview() {
        continuation?.yield(.init())
    }
}

private actor AnalyticsDataProviderStub: AnalyticsDataProviding {
    private let results: [Result<AnalyticsDataModel, Error>]
    private var nextIndex = 0
    private(set) var fetchCalls: [MainSummaryPeriod] = []

    init(results: [Result<AnalyticsDataModel, Error>]) {
        self.results = results
    }

    func fetchData(for period: MainSummaryPeriod) async throws -> AnalyticsDataModel {
        fetchCalls.append(period)
        guard results.isEmpty == false else {
            return AnalyticsDataModel(
                monthStart: period.from,
                totalAmount: 0,
                currency: "USD",
                categories: []
            )
        }

        let index = min(nextIndex, max(results.count - 1, 0))
        nextIndex += 1
        return try results[index].get()
    }

    func recordedFetchCalls() -> [MainSummaryPeriod] {
        fetchCalls
    }
}

private final class MainSummaryPeriodServiceStub: MainSummaryPeriodServicing, @unchecked Sendable {
    private var period: MainSummaryPeriod

    init(period: MainSummaryPeriod) {
        self.period = period
    }

    func currentMonthPeriod() -> MainSummaryPeriod {
        period
    }

    func updatePeriod(from: Date, to: Date) {
        period = .init(
            from: from,
            to: to
        )
    }
}
