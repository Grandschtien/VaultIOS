import Foundation
import NetworkClient

protocol ExpenseAIEntrySubscriptionLimitErrorResolving: Sendable {
    func isSubscriptionLimitError(_ error: Error) -> Bool
}

final class ExpenseAIEntrySubscriptionLimitErrorResolver: ExpenseAIEntrySubscriptionLimitErrorResolving {
    private enum Constants {
        static let tooManyRequestsStatusCode = 429
    }

    func isSubscriptionLimitError(_ error: Error) -> Bool {
        guard case let NetworkClientError.statusCode(code, _, _) = error else {
            return false
        }

        return code == Constants.tooManyRequestsStatusCode
    }
}
