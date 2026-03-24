// Created by Egor Shkarin 24.03.2026

import Foundation
import Alamofire
import NetworkClient

enum SummaryAPI: ApiTarget, Sendable {
    case all(SummaryQueryParameters)
    case byCategory(id: String, parameters: SummaryQueryParameters)

    var host: String {
        MainAPIConfiguration.host
    }

    var path: String {
        switch self {
        case .all:
            "/expenses/summary"
        case let .byCategory(id, _):
            "/expenses/summary/\(id)"
        }
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
        let parameters: SummaryQueryParameters

        switch self {
        case let .all(requestParameters):
            parameters = requestParameters
        case let .byCategory(_, requestParameters):
            parameters = requestParameters
        }

        let query = parameters.toQueryParameters()
        if query.isEmpty {
            return .plain
        }

        return .query(query: query, encoding: URLEncoding.queryString)
    }

    var url: URL {
        MainAPIConfiguration.url(path: path)
    }
}

private extension SummaryQueryParameters {
    func toQueryParameters() -> Parameters {
        MainAPIQueryBuilder.parameters(
            from: [
                "from": from.map(MainAPIQueryBuilder.string(from:)),
                "to": to.map(MainAPIQueryBuilder.string(from:))
            ]
        )
    }
}
