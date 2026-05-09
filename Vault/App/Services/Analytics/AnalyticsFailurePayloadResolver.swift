import Alamofire
import Foundation
import NetworkClient

protocol AnalyticsFailurePayloadResolving: Sendable {
    func makePayload(for error: Error) -> [String: Any]
}

final class AnalyticsFailurePayloadResolver: AnalyticsFailurePayloadResolving {
    func makePayload(for error: Error) -> [String: Any] {
        var payload: [String: Any] = [:]

        if let statusCode = resolveStatusCode(from: error) {
            payload["http_status_code"] = statusCode
        }

        let description = error.localizedDescription
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if !description.isEmpty {
            payload["error_description"] = description
        }

        return payload
    }
}

private extension AnalyticsFailurePayloadResolver {
    func resolveStatusCode(from error: Error) -> Int? {
        switch error {
        case let NetworkClientError.statusCode(code, _, _):
            return code
        case let NetworkClientError.underlying(underlyingError, _, _):
            if case let AFError.responseValidationFailed(reason) = underlyingError,
               case let .unacceptableStatusCode(code) = reason {
                return code
            }

            return nil
        default:
            return nil
        }
    }
}
