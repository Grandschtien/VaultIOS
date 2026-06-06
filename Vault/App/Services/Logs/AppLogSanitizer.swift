import Foundation

final class AppLogSanitizer: @unchecked Sendable {
    private enum Constants {
        static let bodyLimit = 8_192
        static let sensitiveTokens = [
            "authorization",
            "access_token",
            "access-token",
            "accesstoken",
            "refresh_token",
            "refresh-token",
            "refreshtoken",
            "password",
            "token",
            "secret",
            "api_key",
            "api-key",
            "apikey"
        ]
    }

    func sanitizeURL(_ rawURL: String) -> String {
        guard let components = URLComponents(string: rawURL), let queryItems = components.queryItems else {
            return rawURL
        }

        var sanitized = components
        sanitized.queryItems = queryItems.map { item in
            if shouldRedact(key: item.name) {
                return URLQueryItem(name: item.name, value: "<redacted>")
            }

            return item
        }

        return sanitized.string ?? rawURL
    }

    func sanitizeHeaders(_ headers: [String: String]) -> [String] {
        headers
            .sorted { $0.key.localizedCaseInsensitiveCompare($1.key) == .orderedAscending }
            .map { key, value in
                let sanitizedValue = shouldRedact(key: key) ? "<redacted>" : truncate(value)
                return "\(key): \(sanitizedValue)"
            }
    }

    func sanitizeBody(_ body: String) -> String {
        let trimmedBody = truncate(body)

        if isBinaryMarker(trimmedBody) {
            return trimmedBody
        }

        if let sanitizedJSON = sanitizeJSONBody(trimmedBody) {
            return truncate(sanitizedJSON)
        }

        if let sanitizedQueryBody = sanitizeQueryBody(trimmedBody) {
            return truncate(sanitizedQueryBody)
        }

        return truncate(sanitizeTextBody(trimmedBody))
    }
}

private extension AppLogSanitizer {
    func sanitizeJSONBody(_ body: String) -> String? {
        guard let data = body.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: data)
        else {
            return nil
        }

        let sanitizedObject = sanitizeJSONObject(jsonObject, keyPath: nil)
        guard JSONSerialization.isValidJSONObject(sanitizedObject),
              let sanitizedData = try? JSONSerialization.data(withJSONObject: sanitizedObject),
              let sanitizedString = String(data: sanitizedData, encoding: .utf8)
        else {
            return nil
        }

        return sanitizedString
    }

    func sanitizeJSONObject(_ object: Any, keyPath: String?) -> Any {
        switch object {
        case let dictionary as [String: Any]:
            return dictionary.reduce(into: [String: Any]()) { partialResult, element in
                if shouldRedact(key: element.key) || keyPath.map(shouldRedact(key:)) == true {
                    partialResult[element.key] = "<redacted>"
                } else {
                    partialResult[element.key] = sanitizeJSONObject(
                        element.value,
                        keyPath: element.key
                    )
                }
            }
        case let array as [Any]:
            return array.map { sanitizeJSONObject($0, keyPath: keyPath) }
        default:
            return object
        }
    }

    func sanitizeQueryBody(_ body: String) -> String? {
        let segments = body.split(separator: "&")
        guard segments.count > 1 || body.contains("=") else {
            return nil
        }

        let sanitizedSegments = segments.map { segment -> String in
            let parts = segment.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            guard let key = parts.first.map(String.init) else {
                return String(segment)
            }

            if shouldRedact(key: key) {
                return "\(key)=<redacted>"
            }

            guard parts.count > 1 else {
                return key
            }

            return "\(key)=\(parts[1])"
        }

        return sanitizedSegments.joined(separator: "&")
    }

    func sanitizeTextBody(_ body: String) -> String {
        Constants.sensitiveTokens.reduce(body) { partialResult, token in
            redactAssignments(in: partialResult, token: token)
        }
    }

    func redactAssignments(in value: String, token: String) -> String {
        let patterns = [
            "(?i)(\(NSRegularExpression.escapedPattern(for: token))\\s*[=:]\\s*)(\"[^\"]*\"|[^\\s,&]+)",
            "(?i)(\(NSRegularExpression.escapedPattern(for: token))\"\\s*:\\s*)(\"[^\"]*\")"
        ]

        return patterns.reduce(value) { partialResult, pattern in
            guard let expression = try? NSRegularExpression(pattern: pattern) else {
                return partialResult
            }

            let range = NSRange(partialResult.startIndex..., in: partialResult)
            return expression.stringByReplacingMatches(
                in: partialResult,
                options: [],
                range: range,
                withTemplate: "$1<redacted>"
            )
        }
    }

    func shouldRedact(key: String) -> Bool {
        let normalizedKey = key
            .replacingOccurrences(of: "-", with: "_")
            .lowercased()

        return Constants.sensitiveTokens.contains { normalizedKey.contains($0) }
    }

    func truncate(_ value: String) -> String {
        guard value.count > Constants.bodyLimit else {
            return value
        }

        let prefix = value.prefix(Constants.bodyLimit)
        return "\(prefix)…<truncated>"
    }

    func isBinaryMarker(_ body: String) -> Bool {
        body.hasPrefix("<") && body.contains("bytes binary>")
    }
}
