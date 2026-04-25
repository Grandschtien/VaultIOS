import Foundation
import Alamofire
import NetworkClient

protocol CategoryEditorSubscriptionLimitErrorResolving: Sendable {
    func isSubscriptionLimitError(_ error: Error) -> Bool
}

final class CategoryEditorSubscriptionLimitErrorResolver: CategoryEditorSubscriptionLimitErrorResolving {
    private enum Constants {
        static let tooManyRequestsStatusCode = 429
    }

    func isSubscriptionLimitError(_ error: Error) -> Bool {
        if case let NetworkClientError.statusCode(code, _, _) = error {
            return code == Constants.tooManyRequestsStatusCode
        }

        guard case let NetworkClientError.underlying(underlyingError, _, _) = error,
              let afError = underlyingError.asAFError,
              case let AFError.responseValidationFailed(reason) = afError,
              case let .unacceptableStatusCode(code) = reason
        else {
            return false
        }

        return code == Constants.tooManyRequestsStatusCode
    }
}
