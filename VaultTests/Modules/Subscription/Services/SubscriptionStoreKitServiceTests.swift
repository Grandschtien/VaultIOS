import XCTest
@testable import Vault

final class SubscriptionStoreKitServiceTests: XCTestCase {
    func testLoadPlansReturnsCatalogOrder() async throws {
        let client = SubscriptionStoreKitClientSpy(
            productsResult: .success(
                [
                    .init(id: SubscriptionCatalog.premium.id, price: "$2.99"),
                    .init(id: SubscriptionCatalog.plus.id, price: "$1.99")
                ]
            )
        )
        let sut = SubscriptionStoreKitService(
            client: client,
            appAccountTokenProvider: SubscriptionAppAccountTokenProviderSpy()
        )

        let plans = try await sut.loadPlans()

        XCTAssertEqual(
            plans.map(\.id),
            [SubscriptionCatalog.plus.id, SubscriptionCatalog.premium.id]
        )
        XCTAssertEqual(
            plans.map(\.title),
            [L10n.subscriptionPlus, L10n.subscriptionPremium]
        )
        XCTAssertEqual(plans.map(\.price), ["$1.99", "$2.99"])
    }
}

extension SubscriptionStoreKitServiceTests {
    func testPurchasePassesAppAccountTokenAndFinishDelegatesToClient() async throws {
        let verifiedPurchase = SubscriptionVerifiedPurchase(
            productId: SubscriptionCatalog.plus.id,
            transactionId: "transaction-1",
            originalTransactionId: "original-1",
            signedTransaction: "signed-transaction",
            purchaseDate: Date(timeIntervalSince1970: 1_775_001_600),
            environment: "xcode"
        )
        let appAccountToken = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let client = SubscriptionStoreKitClientSpy(
            purchaseResult: .success(.verified(verifiedPurchase))
        )
        let sut = SubscriptionStoreKitService(
            client: client,
            appAccountTokenProvider: SubscriptionAppAccountTokenProviderSpy(
                appAccountToken: appAccountToken
            )
        )

        let result = try await sut.purchase(planID: SubscriptionCatalog.plus.id)
        try await sut.finishPurchase(transactionID: verifiedPurchase.transactionId)
        let purchasedIDs = await client.purchaseProductIDs()
        let purchasedAppAccountTokens = await client.purchasedAppAccountTokens()
        let finishedIDs = await client.finishedTransactionIDs()

        XCTAssertEqual(result, .verified(verifiedPurchase))
        XCTAssertEqual(purchasedIDs, [SubscriptionCatalog.plus.id])
        XCTAssertEqual(purchasedAppAccountTokens, [appAccountToken])
        XCTAssertEqual(finishedIDs, [verifiedPurchase.transactionId])
    }
}

private final class SubscriptionStoreKitClientSpy: SubscriptionStoreKitClientProtocol, @unchecked Sendable {
    private let productsResult: Result<[SubscriptionStoreKitClientProduct], Error>
    private let purchaseResult: Result<SubscriptionPurchaseResult, Error>
    private let state = State()

    init(
        productsResult: Result<[SubscriptionStoreKitClientProduct], Error> = .success([]),
        purchaseResult: Result<SubscriptionPurchaseResult, Error> = .success(.cancelled)
    ) {
        self.productsResult = productsResult
        self.purchaseResult = purchaseResult
    }

    func products(for productIDs: [String]) async throws -> [SubscriptionStoreKitClientProduct] {
        try productsResult.get()
    }

    func purchase(productID: String, appAccountToken: UUID) async throws -> SubscriptionPurchaseResult {
        await state.recordPurchase(productID: productID, appAccountToken: appAccountToken)
        return try purchaseResult.get()
    }

    func finish(transactionID: String) async throws {
        await state.recordFinish(transactionID: transactionID)
    }

    func makeTransactionUpdatesStream() -> AsyncStream<SubscriptionVerifiedPurchase> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }

    func purchaseProductIDs() async -> [String] {
        await state.purchaseProductIDs()
    }

    func purchasedAppAccountTokens() async -> [UUID] {
        await state.purchasedAppAccountTokens()
    }

    func finishedTransactionIDs() async -> [String] {
        await state.finishedTransactionIDs()
    }
}

private extension SubscriptionStoreKitClientSpy {
    actor State {
        private var capturedProductIDs: [String] = []
        private var capturedAppAccountTokens: [UUID] = []
        private var recordedFinishedTransactionIDs: [String] = []

        func recordPurchase(productID: String, appAccountToken: UUID) {
            capturedProductIDs.append(productID)
            capturedAppAccountTokens.append(appAccountToken)
        }

        func recordFinish(transactionID: String) {
            recordedFinishedTransactionIDs.append(transactionID)
        }

        func purchaseProductIDs() -> [String] {
            capturedProductIDs
        }

        func purchasedAppAccountTokens() -> [UUID] {
            capturedAppAccountTokens
        }

        func finishedTransactionIDs() -> [String] {
            recordedFinishedTransactionIDs
        }
    }
}

private struct SubscriptionAppAccountTokenProviderSpy: SubscriptionAppAccountTokenProviding {
    let appAccountToken: UUID

    init(appAccountToken: UUID = UUID()) {
        self.appAccountToken = appAccountToken
    }

    func currentAppAccountToken() throws -> UUID {
        appAccountToken
    }
}
