// Created by Egor Shkarin 29.03.2026

import Foundation
import Alamofire
import NetworkClient

enum ProfileAPI: ApiTarget, Sendable {
    case get
    case update(ProfileUpdateRequestDTO)

    var host: String {
        MainAPIConfiguration.host
    }

    var path: String {
        switch self {
        case .get, .update:
            "/profile"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .get:
            .get
        case .update:
            .patch
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
        case .get:
            .plain
        case let .update(dto):
            .custonJSON(data: dto, encoder: JSONCoder.encoder)
        }
    }

    var url: URL {
        MainAPIConfiguration.url(path: path)
    }
}
