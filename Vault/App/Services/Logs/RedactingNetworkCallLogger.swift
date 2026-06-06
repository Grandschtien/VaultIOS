import Foundation
import NetworkClient

final class RedactingNetworkCallLogger: NetworkCallLogger, @unchecked Sendable {
    private let appLogService: AppLogServiceProtocol
    private let sanitizer: AppLogSanitizer

    init(
        appLogService: AppLogServiceProtocol,
        sanitizer: AppLogSanitizer = AppLogSanitizer()
    ) {
        self.appLogService = appLogService
        self.sanitizer = sanitizer
    }

    func logRequest(_ entry: NetworkRequestLogEntry) {
        appLogService.log(
            category: .network,
            name: "request",
            source: "NetworkClient",
            payload: [
                "method": entry.method,
                "url": sanitizer.sanitizeURL(entry.url),
                "headers": sanitizer.sanitizeHeaders(entry.headers),
                "body": sanitizer.sanitizeBody(entry.body)
            ],
            requestID: entry.requestID,
            subscriptionAttemptID: nil
        )
    }

    func logResponse(_ entry: NetworkResponseLogEntry) {
        var payload: [String: Any] = [
            "method": entry.method,
            "url": sanitizer.sanitizeURL(entry.url),
            "body": sanitizer.sanitizeBody(entry.body)
        ]
        if let statusCode = entry.statusCode {
            payload["status_code"] = statusCode
        }
        if let durationMs = entry.durationMs {
            payload["duration_ms"] = durationMs
        }
        if let errorDescription = entry.errorDescription, !errorDescription.isEmpty {
            payload["error_description"] = sanitizer.sanitizeBody(errorDescription)
        }

        appLogService.log(
            category: .network,
            name: "response",
            source: "NetworkClient",
            payload: payload,
            requestID: entry.requestID,
            subscriptionAttemptID: nil
        )
    }
}
