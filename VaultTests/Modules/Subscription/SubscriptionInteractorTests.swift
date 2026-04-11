import XCTest
@testable import Vault

@MainActor
final class SubscriptionInteractorTests: XCTestCase {
    func testFetchDataSuccessPublishesLoadingThenLoaded() async {
        let presenter = SubscriptionPresenterSpy()
        let router = SubscriptionRouterSpy()
        let output = SubscriptionOutputSpy()
        let storeKitService = SubscriptionStoreKitServiceStub(
            loadPlansResult: .success(
                [
                    .init(
                        id: SubscriptionCatalog.plus.id,
                        title: L10n.subscriptionPlus,
                        price: "$1.99"
                    ),
                    .init(
                        id: SubscriptionCatalog.premium.id,
                        title: L10n.subscriptionPremium,
                        price: "$2.99"
                    )
                ]
            )
        )
        let sut = makeSut(
            presenter: presenter,
            router: router,
            output: output,
            storeKitService: storeKitService
        )

        await sut.fetchData()
        let loadPlansCallsCount = await storeKitService.loadPlansCallsCount()

        guard let first = presenter.presentedData.first,
              let last = presenter.presentedData.last else {
            return XCTFail("Expected presenter updates")
        }

        assertStatus(first.loadingState, is: .loading)
        assertStatus(last.loadingState, is: .loaded)
        XCTAssertEqual(last.plans.count, 2)
        XCTAssertEqual(loadPlansCallsCount, 1)
    }
}

extension SubscriptionInteractorTests {
    func testFetchDataFailurePublishesFailedState() async {
        let presenter = SubscriptionPresenterSpy()
        let router = SubscriptionRouterSpy()
        let output = SubscriptionOutputSpy()
        let storeKitService = SubscriptionStoreKitServiceStub(
            loadPlansResult: .failure(StubError.any)
        )
        let sut = makeSut(
            presenter: presenter,
            router: router,
            output: output,
            storeKitService: storeKitService
        )

        await sut.fetchData()

        guard let first = presenter.presentedData.first,
              let last = presenter.presentedData.last else {
            return XCTFail("Expected presenter updates")
        }

        assertStatus(first.loadingState, is: .loading)
        assertStatus(last.loadingState, is: .failed)
    }
}

extension SubscriptionInteractorTests {
    func testHandleTapPurchaseVerifiedApprovesFinishesClosesAndNotifiesOutput() async {
        let presenter = SubscriptionPresenterSpy()
        let router = SubscriptionRouterSpy()
        let output = SubscriptionOutputSpy()
        let storeKitService = SubscriptionStoreKitServiceStub(
            loadPlansResult: .success(defaultPlans),
            purchaseResult: .success(.verified(defaultVerifiedPurchase))
        )
        let contractService = SubscriptionContractServiceSpy()
        let sut = makeSut(
            presenter: presenter,
            router: router,
            output: output,
            storeKitService: storeKitService,
            contractService: contractService
        )

        await sut.fetchData()
        await sut.handleTapPurchase(planID: SubscriptionCatalog.plus.id)
        let approvedRequests = await contractService.approvedRequests()
        let finishedTransactionIDs = await storeKitService.finishedTransactionIDs()
        let outputCallsCount = await output.callsCount()

        XCTAssertEqual(approvedRequests.count, 1)
        XCTAssertEqual(finishedTransactionIDs, [defaultVerifiedPurchase.transactionId])
        XCTAssertEqual(outputCallsCount, 1)
        XCTAssertEqual(router.closeCallsCount, 1)
    }
}

extension SubscriptionInteractorTests {
    func testHandleTapPurchasePendingDoesNotSync() async {
        let presenter = SubscriptionPresenterSpy()
        let router = SubscriptionRouterSpy()
        let output = SubscriptionOutputSpy()
        let storeKitService = SubscriptionStoreKitServiceStub(
            loadPlansResult: .success(defaultPlans),
            purchaseResult: .success(.pending)
        )
        let contractService = SubscriptionContractServiceSpy()
        let sut = makeSut(
            presenter: presenter,
            router: router,
            output: output,
            storeKitService: storeKitService,
            contractService: contractService
        )

        await sut.fetchData()
        await sut.handleTapPurchase(planID: SubscriptionCatalog.plus.id)
        let approvedRequests = await contractService.approvedRequests()
        let finishedTransactionIDs = await storeKitService.finishedTransactionIDs()
        let outputCallsCount = await output.callsCount()

        XCTAssertTrue(approvedRequests.isEmpty)
        XCTAssertTrue(finishedTransactionIDs.isEmpty)
        XCTAssertEqual(outputCallsCount, 0)
        XCTAssertEqual(router.closeCallsCount, 0)
        XCTAssertEqual(router.presentedMessages, [L10n.subscriptionPurchasePending])
    }
}

extension SubscriptionInteractorTests {
    func testHandleTapPurchaseCancelledDoesNotSync() async {
        let presenter = SubscriptionPresenterSpy()
        let router = SubscriptionRouterSpy()
        let output = SubscriptionOutputSpy()
        let storeKitService = SubscriptionStoreKitServiceStub(
            loadPlansResult: .success(defaultPlans),
            purchaseResult: .success(.cancelled)
        )
        let contractService = SubscriptionContractServiceSpy()
        let sut = makeSut(
            presenter: presenter,
            router: router,
            output: output,
            storeKitService: storeKitService,
            contractService: contractService
        )

        await sut.fetchData()
        await sut.handleTapPurchase(planID: SubscriptionCatalog.plus.id)
        let approvedRequests = await contractService.approvedRequests()
        let finishedTransactionIDs = await storeKitService.finishedTransactionIDs()
        let outputCallsCount = await output.callsCount()

        XCTAssertTrue(approvedRequests.isEmpty)
        XCTAssertTrue(finishedTransactionIDs.isEmpty)
        XCTAssertEqual(outputCallsCount, 0)
        XCTAssertEqual(router.closeCallsCount, 0)
    }
}

extension SubscriptionInteractorTests {
    func testHandleTapPurchaseUnverifiedDoesNotSyncAndPresentsError() async {
        let presenter = SubscriptionPresenterSpy()
        let router = SubscriptionRouterSpy()
        let output = SubscriptionOutputSpy()
        let storeKitService = SubscriptionStoreKitServiceStub(
            loadPlansResult: .success(defaultPlans),
            purchaseResult: .success(.unverified)
        )
        let contractService = SubscriptionContractServiceSpy()
        let sut = makeSut(
            presenter: presenter,
            router: router,
            output: output,
            storeKitService: storeKitService,
            contractService: contractService
        )

        await sut.fetchData()
        await sut.handleTapPurchase(planID: SubscriptionCatalog.plus.id)
        let approvedRequests = await contractService.approvedRequests()
        let finishedTransactionIDs = await storeKitService.finishedTransactionIDs()
        let outputCallsCount = await output.callsCount()

        XCTAssertTrue(approvedRequests.isEmpty)
        XCTAssertTrue(finishedTransactionIDs.isEmpty)
        XCTAssertEqual(outputCallsCount, 0)
        XCTAssertEqual(router.closeCallsCount, 0)
        XCTAssertEqual(router.presentedErrors, [L10n.subscriptionPurchaseUnverified])
    }
}

extension SubscriptionInteractorTests {
    func testHandleTapPurchaseWhenSyncFailsDoesNotFinishOrClose() async {
        let presenter = SubscriptionPresenterSpy()
        let router = SubscriptionRouterSpy()
        let output = SubscriptionOutputSpy()
        let storeKitService = SubscriptionStoreKitServiceStub(
            loadPlansResult: .success(defaultPlans),
            purchaseResult: .success(.verified(defaultVerifiedPurchase))
        )
        let contractService = SubscriptionContractServiceSpy(
            nextError: StubError.any
        )
        let sut = makeSut(
            presenter: presenter,
            router: router,
            output: output,
            storeKitService: storeKitService,
            contractService: contractService
        )

        await sut.fetchData()
        await sut.handleTapPurchase(planID: SubscriptionCatalog.plus.id)
        let approvedRequests = await contractService.approvedRequests()
        let finishedTransactionIDs = await storeKitService.finishedTransactionIDs()
        let outputCallsCount = await output.callsCount()

        XCTAssertEqual(approvedRequests.count, 1)
        XCTAssertTrue(finishedTransactionIDs.isEmpty)
        XCTAssertEqual(outputCallsCount, 0)
        XCTAssertEqual(router.closeCallsCount, 0)
        XCTAssertEqual(router.presentedErrors.count, 1)
    }
}

private extension SubscriptionInteractorTests {
    var defaultPlans: [SubscriptionStorePlan] {
        [
            .init(
                id: SubscriptionCatalog.plus.id,
                title: L10n.subscriptionPlus,
                price: "$1.99"
            ),
            .init(
                id: SubscriptionCatalog.premium.id,
                title: L10n.subscriptionPremium,
                price: "$2.99"
            )
        ]
    }

    var defaultVerifiedPurchase: SubscriptionVerifiedPurchase {
        .init(
            productId: SubscriptionCatalog.plus.id,
            transactionId: "transaction-1",
            originalTransactionId: "original-1",
            signedTransaction: "signed-transaction",
            purchaseDate: Date(timeIntervalSince1970: 1_775_001_600),
            environment: "xcode"
        )
    }

    enum LoadingStatusCase {
        case loading
        case loaded
        case failed
    }

    func makeSut(
        presenter: SubscriptionPresentationLogic,
        router: SubscriptionRoutingLogic,
        output: SubscriptionOutput,
        storeKitService: SubscriptionStoreKitServicing,
        contractService: SubscriptionContractServicing = SubscriptionContractServiceSpy()
    ) -> SubscriptionInteractor {
        SubscriptionInteractor(
            presenter: presenter,
            router: router,
            currentTier: "",
            output: output,
            storeKitService: storeKitService,
            contractService: contractService
        )
    }

    func assertStatus(
        _ status: LoadingStatus,
        is expected: LoadingStatusCase,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        switch (status, expected) {
        case (.loading, .loading), (.loaded, .loaded), (.failed, .failed):
            XCTAssertTrue(true, file: file, line: line)
        default:
            XCTFail("Unexpected status", file: file, line: line)
        }
    }

    enum StubError: Error {
        case any
    }
}

@MainActor
private final class SubscriptionPresenterSpy: SubscriptionPresentationLogic {
    private(set) var presentedData: [SubscriptionFetchData] = []

    func presentFetchedData(_ data: SubscriptionFetchData) {
        presentedData.append(data)
    }
}

@MainActor
private final class SubscriptionRouterSpy: SubscriptionRoutingLogic {
    private(set) var closeCallsCount = 0
    private(set) var presentedErrors: [String] = []
    private(set) var presentedMessages: [String] = []

    func close() {
        closeCallsCount += 1
    }

    func presentError(with text: String) {
        presentedErrors.append(text)
    }

    func presentMessage(with text: String) {
        presentedMessages.append(text)
    }
}

private actor SubscriptionOutputSpy: SubscriptionOutput {
    private var didSyncCallsCount = 0

    func handleSubscriptionDidSync() async {
        didSyncCallsCount += 1
    }

    func callsCount() -> Int {
        didSyncCallsCount
    }
}

private final class SubscriptionStoreKitServiceStub: SubscriptionStoreKitServicing, @unchecked Sendable {
    private let loadPlansResult: Result<[SubscriptionStorePlan], Error>
    private let purchaseResult: Result<SubscriptionPurchaseResult, Error>
    private let updates: [SubscriptionVerifiedPurchase]
    private let state = State()

    init(
        loadPlansResult: Result<[SubscriptionStorePlan], Error>,
        purchaseResult: Result<SubscriptionPurchaseResult, Error> = .success(.cancelled),
        updates: [SubscriptionVerifiedPurchase] = []
    ) {
        self.loadPlansResult = loadPlansResult
        self.purchaseResult = purchaseResult
        self.updates = updates
    }

    func loadPlans() async throws -> [SubscriptionStorePlan] {
        await state.incrementLoadCallsCount()
        return try loadPlansResult.get()
    }

    func purchase(planID: String) async throws -> SubscriptionPurchaseResult {
        try purchaseResult.get()
    }

    func finishPurchase(transactionID: String) async throws {
        await state.appendFinishedTransactionID(transactionID)
    }

    func makeTransactionUpdatesStream() -> AsyncStream<SubscriptionVerifiedPurchase> {
        return AsyncStream { continuation in
            for update in updates {
                continuation.yield(update)
            }
            continuation.finish()
        }
    }

    func loadPlansCallsCount() async -> Int {
        await state.loadCallsCount()
    }

    func finishedTransactionIDs() async -> [String] {
        await state.finishedTransactionIDs()
    }
}

private extension SubscriptionStoreKitServiceStub {
    actor State {
        private var loadCallsCount = 0
        private var finishedTransactionIDs: [String] = []

        func incrementLoadCallsCount() {
            loadCallsCount += 1
        }

        func appendFinishedTransactionID(_ transactionID: String) {
            finishedTransactionIDs.append(transactionID)
        }

        func loadCallsCount() -> Int {
            loadCallsCount
        }

        func finishedTransactionIDs() -> [String] {
            finishedTransactionIDs
        }
    }
}

private actor SubscriptionContractServiceSpy: SubscriptionContractServicing {
    private let nextError: Error?
    private var requests: [SubscriptionApproveRequestDTO] = []

    init(nextError: Error? = nil) {
        self.nextError = nextError
    }

    func approvePurchase(_ request: SubscriptionApproveRequestDTO) async throws {
        requests.append(request)

        if let nextError {
            throw nextError
        }
    }

    func approvedRequests() -> [SubscriptionApproveRequestDTO] {
        requests
    }
}
