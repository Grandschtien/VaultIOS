// Created by Egor Shkarin 06.06.2026

import Foundation
import Alamofire
import NetworkClient

enum AccountAPI: ApiTarget, Sendable {
    case delete

    var host: String {
        MainAPIConfiguration.host
    }

    var path: String {
        "/account"
    }

    var method: HTTPMethod {
        .delete
    }

    var headers: [String : String] {
        [:]
    }

    var timeoutInterval: TimeInterval {
        MainAPIConfiguration.timeoutInterval
    }

    var requestType: RequestType {
        .plain
    }

    var url: URL {
        MainAPIConfiguration.url(path: path)
    }
}
