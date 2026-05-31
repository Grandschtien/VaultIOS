// Created by Egor Shkarin 31.05.2026

import Foundation
import Alamofire
import NetworkClient

enum SubscriptionAccessAPI: ApiTarget, Sendable {
    case get

    var host: String {
        MainAPIConfiguration.host
    }

    var path: String {
        switch self {
        case .get:
            "/user/subscription"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .get:
            .get
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
        }
    }

    var url: URL {
        MainAPIConfiguration.url(path: path)
    }
}
