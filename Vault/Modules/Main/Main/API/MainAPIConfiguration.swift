// Created by Codex on 24.03.2026

import Foundation
import Alamofire

enum MainAPIConfiguration {
    static let host = "localhost"
    static let port = 8080
    static let scheme = "http"
    static let timeoutInterval: TimeInterval = 30

    static func url(path: String) -> URL {
        var components = URLComponents()
        components.host = host
        components.port = port
        components.scheme = scheme
        components.path = path

        guard let url = components.url else {
            fatalError("Failed to build url for path: \(path)")
        }

        return url
    }
}

enum MainAPIQueryBuilder {
    private static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: .zero)
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static func string(from date: Date) -> String {
        dateFormatter.string(from: date)
    }

    static func parameters(from values: [String: Any?]) -> Parameters {
        values.reduce(into: Parameters()) { partialResult, element in
            if let value = element.value {
                partialResult[element.key] = value
            }
        }
    }
}
