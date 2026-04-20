// Created by Egor Shkarin 08.04.2026

import Foundation
import Alamofire
import NetworkClient

enum SubscriptionAPI: ApiTarget, Sendable {
    case approve

    var host: String {
        MainAPIConfiguration.host
    }

    var path: String {
        switch self {
        case .approve:
            "/subscriptions/apple/approve"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .approve:
            .post
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
        case .approve:
            .plain
        }
    }

    var url: URL {
        MainAPIConfiguration.url(path: path)
    }
}
