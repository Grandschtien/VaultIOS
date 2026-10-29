import FirebaseAnalytics
import FirebaseCore
import RevenueCat
import StoreKit

// sourcery: AutoMockable
protocol FirebaseTransactionLogging: Sendable {
    func trackTransactionIfNeeded(_ transaction: StoreTransaction?) async
}

final class FirebaseTransactionLogger: FirebaseTransactionLogging, @unchecked Sendable {
    typealias TransactionLogAction = @Sendable () async -> Void
    typealias TransactionLogActionResolver = @Sendable (StoreTransaction) -> TransactionLogAction?

    private let configureIfNeededHandler: @Sendable () async -> Void
    private let transactionLogActionResolver: TransactionLogActionResolver

    init(
        configureIfNeededHandler: @escaping @Sendable () async -> Void = {
            await MainActor.run {
                if FirebaseApp.app() == nil {
                    FirebaseApp.configure()
                }
            }
        },
        transactionLogActionResolver: @escaping TransactionLogActionResolver = { transaction in
            guard #available(iOS 15.0, *),
                  let sk2Transaction = transaction.sk2Transaction else {
                return nil
            }

            return {
                await MainActor.run {
                    Analytics.logTransaction(sk2Transaction)
                }
            }
        }
    ) {
        self.configureIfNeededHandler = configureIfNeededHandler
        self.transactionLogActionResolver = transactionLogActionResolver
    }

    func trackTransactionIfNeeded(_ transaction: StoreTransaction?) async {
        guard let transaction,
              let transactionLogAction = transactionLogActionResolver(transaction) else {
            return
        }

        await configureIfNeededHandler()
        await transactionLogAction()
    }
}
