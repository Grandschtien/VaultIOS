// Created by Egor Shkarin 08.04.2026

import Foundation

struct SubscriptionApproveRequestDTO: Codable, Equatable, Sendable {
    let signedTransactionInfo: String
}

extension SubscriptionApproveRequestDTO {
    init(purchase: SubscriptionVerifiedPurchase) {
        self.init(
            signedTransactionInfo: purchase.signedTransaction
        )
    }
}
