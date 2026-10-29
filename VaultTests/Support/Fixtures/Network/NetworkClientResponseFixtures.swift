import Foundation
@testable import NetworkClient

enum NetworkClientResponseFixtures {
    static func makeResponse(statusCode: Int) -> Response {
        NetworkClientResponse(
            data: nil,
            request: nil,
            response: HTTPURLResponse(
                url: URL(string: "https://example.com")!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )
        )
    }
}
