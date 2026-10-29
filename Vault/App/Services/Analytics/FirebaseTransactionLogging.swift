import RevenueCat

// sourcery: AutoMockable
protocol FirebaseTransactionLogging: Sendable {
    func trackTransactionIfNeeded(_ transaction: StoreTransaction?) async
}

final class FirebaseTransactionLogger: FirebaseTransactionLogging {
    private let client: FirebaseAnalyticsClientProtocol

    init(client: FirebaseAnalyticsClientProtocol = FirebaseAnalyticsClient()) {
        self.client = client
    }

    func trackTransactionIfNeeded(_ transaction: StoreTransaction?) async {
        guard let transaction else {
            return
        }

        await client.logTransaction(transaction)
    }
}
