import Foundation
import Alamofire
import NetworkClient

enum AIParseAPI: ApiTarget, Sendable {
    case parse(AIParseRequestDTO)

    var host: String {
        MainAPIConfiguration.host
    }

    var path: String {
        "/ai/parse"
    }

    var method: HTTPMethod {
        .post
    }

    var headers: [String : String] {
        [:]
    }

    var timeoutInterval: TimeInterval {
        MainAPIConfiguration.timeoutInterval
    }

    var requestType: RequestType {
        switch self {
        case let .parse(dto):
            return .custonJSON(data: dto, encoder: JSONCoder.encoder)
        }
    }

    var url: URL {
        MainAPIConfiguration.url(path: path)
    }
}
