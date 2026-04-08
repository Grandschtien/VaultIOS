// Created by Egor Shkarin 24.03.2026

import Foundation
import Alamofire
import NetworkClient

enum CategoriesAPI: ApiTarget, Sendable {
    case create(CategoryCreateRequestDTO)
    case update(id: String, CategoryCreateRequestDTO)
    case list(CategoriesQueryParameters)
    case get(id: String, parameters: CategoriesQueryParameters)
    case delete(id: String)

    var host: String {
        MainAPIConfiguration.host
    }

    var path: String {
        switch self {
        case .create, .list:
            "/categories"
        case let .update(id, _), let .get(id, _), let .delete(id):
            "/categories/\(id)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .create, .update:
            .post
        case .list, .get:
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
        case let .create(dto), let .update(_, dto):
            .custonJSON(data: dto, encoder: JSONCoder.encoder)
        case let .list(parameters):
            queryRequestType(for: parameters)
        case let .get(_, parameters):
            queryRequestType(for: parameters)
        case .delete:
            .plain
        }
    }

    var url: URL {
        MainAPIConfiguration.url(path: path)
    }
}

private extension CategoriesAPI {
    func queryRequestType(for parameters: CategoriesQueryParameters) -> RequestType {
        let query = parameters.toQueryParameters()
        if query.isEmpty {
            return .plain
        }

        return .query(query: query, encoding: URLEncoding.queryString)
    }
}

private extension CategoriesQueryParameters {
    func toQueryParameters() -> Parameters {
        MainAPIQueryBuilder.parameters(
            from: [
                "from": from.map(MainAPIQueryBuilder.string(from:)),
                "to": to.map(MainAPIQueryBuilder.string(from:))
            ]
        )
    }
}
