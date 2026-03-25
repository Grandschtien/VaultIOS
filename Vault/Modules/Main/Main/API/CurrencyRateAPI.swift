// Created by Codex on 25.03.2026

import Foundation
import Alamofire
import NetworkClient

enum CurrencyRateAPI: ApiTarget, Sendable {
    case get(currency: String)

    var host: String {
        MainAPIConfiguration.host
    }

    var path: String {
        "/currency-rate"
    }

    var method: HTTPMethod {
        .get
    }

    var headers: [String : String] {
        [:]
    }

    var timeoutInterval: TimeInterval {
        MainAPIConfiguration.timeoutInterval
    }

    var requestType: RequestType {
        switch self {
        case let .get(currency):
            return .query(
                query: MainAPIQueryBuilder.parameters(
                    from: [
                        "currency": currency
                    ]
                ),
                encoding: URLEncoding.queryString
            )
        }
    }

    var url: URL {
        MainAPIConfiguration.url(path: path)
    }
}
