// Created by Egor Shkarin 24.03.2026

import Foundation
import Alamofire
import NetworkClient

enum ExpensiesAPI: ApiTarget, Sendable {
    case create(ExpensesCreateRequestDTO)
    case list(ExpensesListQueryParameters)
    case delete(id: String)

    var host: String {
        MainAPIConfiguration.host
    }

    var path: String {
        switch self {
        case .create, .list:
            "/expenses"
        case let .delete(id):
            "/expenses/\(id)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .create:
            .post
        case .list:
            .get
        case .delete:
            .delete
        }
    }

    var headers: [String : String] {
        [:]
    }

    var timeoutInterval: TimeInterval {
        MainAPIConfiguration.timeoutInterval
    }

    var requestType: RequestType {
        switch self {
        case let .create(dto):
            return .custonJSON(data: dto, encoder: JSONCoder.encoder)
        case let .list(parameters):
            let query = parameters.toQueryParameters()
            if query.isEmpty {
                return .plain
            }

            return .query(query: query, encoding: URLEncoding.queryString)
        case .delete:
            return .plain
        }
    }

    var url: URL {
        MainAPIConfiguration.url(path: path)
    }
}

private extension ExpensesListQueryParameters {
    func toQueryParameters() -> Parameters {
        MainAPIQueryBuilder.parameters(
            from: [
                "category": category,
                "from": from.map(MainAPIQueryBuilder.string(from:)),
                "to": to.map(MainAPIQueryBuilder.string(from:)),
                "cursor": cursor,
                "limit": limit
            ]
        )
    }
}
