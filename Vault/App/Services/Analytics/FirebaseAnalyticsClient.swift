import FirebaseAnalytics
import FirebaseCore
import RevenueCat

// sourcery: AutoMockable
protocol FirebaseAnalyticsClientProtocol: Sendable {
    func configureIfNeeded() async
    func logEvent(_ name: String, parameters: [String: Any]?) async
    func logTransaction(_ transaction: StoreTransaction) async
}

final class FirebaseAnalyticsClient: FirebaseAnalyticsClientProtocol {
    func configureIfNeeded() async {
        await MainActor.run {
            if FirebaseApp.app() == nil {
                FirebaseApp.configure()
            }
        }
    }

    func logEvent(_ name: String, parameters: [String: Any]?) async {
        await MainActor.run {
            Analytics.logEvent(name, parameters: parameters)
        }
    }

    func logTransaction(_ transaction: StoreTransaction) async {
        guard #available(iOS 15.0, *),
              let sk2Transaction = transaction.sk2Transaction else {
            return
        }

        await configureIfNeeded()
        await MainActor.run {
            Analytics.logTransaction(sk2Transaction)
        }
    }
}
