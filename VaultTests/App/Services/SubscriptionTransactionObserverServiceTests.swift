import XCTest
@testable import Vault

final class SubscriptionTransactionObserverServiceTests: XCTestCase {
    func testStartApprovesVerifiedUpdatesAndFinishesTransactions() async {
        let purchase = SubscriptionVerifiedPurchase(
            productId: SubscriptionCatalog.premium.id,
            transactionId: "transaction-1",
            originalTransactionId: "original-1",
            signedTransaction: "signed-transaction",
            purchaseDate: Date(timeIntervalSince1970: 1_775_001_600),
            environment: "xcode"
        )
        let storeKitService = SubscriptionTransactionObserverStoreKitServiceSpy(
            updates: [purchase]
        )
        let contractService = SubscriptionTransactionObserverContractServiceSpy()
        let sut = SubscriptionTransactionObserverService(
            storeKitService: storeKitService,
            contractService: contractService
        )

        sut.start()
        try? await Task.sleep(nanoseconds: 100_000_000)

        let approvedRequests = await contractService.approvedRequests()
        let finishedIDs = storeKitService.finishedTransactionIDs()

        XCTAssertEqual(approvedRequests, [.init(signedTransaction: "signed-transaction")])
        XCTAssertEqual(finishedIDs, ["transaction-1"])
    }
}

extension SubscriptionTransactionObserverServiceTests {
    func testStartWhenBackendSyncFailsDoesNotFinishTransaction() async {
        let purchase = SubscriptionVerifiedPurchase(
            productId: SubscriptionCatalog.plus.id,
            transactionId: "transaction-2",
            originalTransactionId: "original-2",
            signedTransaction: "signed-transaction-2",
            purchaseDate: Date(timeIntervalSince1970: 1_775_001_600),
            environment: "xcode"
        )
        let storeKitService = SubscriptionTransactionObserverStoreKitServiceSpy(
            updates: [purchase]
        )
        let contractService = SubscriptionTransactionObserverContractServiceSpy(
            nextError: StubError.any
        )
        let sut = SubscriptionTransactionObserverService(
            storeKitService: storeKitService,
            contractService: contractService
        )

        sut.start()
        try? await Task.sleep(nanoseconds: 100_000_000)

        let approvedRequests = await contractService.approvedRequests()
        let finishedIDs = storeKitService.finishedTransactionIDs()

        XCTAssertEqual(approvedRequests, [.init(signedTransaction: "signed-transaction-2")])
        XCTAssertTrue(finishedIDs.isEmpty)
    }
}

private extension SubscriptionTransactionObserverServiceTests {
    enum StubError: Error {
        case any
    }
}

private final class SubscriptionTransactionObserverStoreKitServiceSpy: SubscriptionStoreKitServicing, @unchecked Sendable {
    private let updates: [SubscriptionVerifiedPurchase]
    private let lock = NSLock()
    private var finishedIDs: [String] = []

    init(updates: [SubscriptionVerifiedPurchase]) {
        self.updates = updates
    }

    func loadPlans() async throws -> [SubscriptionStorePlan] {
        []
    }

    func purchase(planID: String) async throws -> SubscriptionPurchaseResult {
        .cancelled
    }

    func finishPurchase(transactionID: String) async throws {
        lock.lock()
        finishedIDs.append(transactionID)
        lock.unlock()
    }

    func makeTransactionUpdatesStream() -> AsyncStream<SubscriptionVerifiedPurchase> {
        return AsyncStream { continuation in
            for update in updates {
                continuation.yield(update)
            }
            continuation.finish()
        }
    }

    func finishedTransactionIDs() -> [String] {
        lock.lock()
        defer { lock.unlock() }
        return finishedIDs
    }
}

private actor SubscriptionTransactionObserverContractServiceSpy: SubscriptionContractServicing {
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
