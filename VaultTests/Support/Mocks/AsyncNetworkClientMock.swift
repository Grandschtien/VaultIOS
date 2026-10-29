import Foundation
import NetworkClient

final class AsyncNetworkClientMock: AsyncNetworkClient, @unchecked Sendable {
    enum MockError: Error {
        case missingResponseData
    }

    var onRequest: ((ApiTarget) -> Void)?
    var onRequestWithoutResponse: ((ApiTarget) -> Void)?
    var nextError: Error?
    var responseDelayNanoseconds: UInt64 = .zero

    private var nextResponseData: Data?
    private(set) var capturedTargets: [ApiTarget] = []

    func setResponse(json: String) {
        nextResponseData = Data(json.utf8)
    }

    func request<T: Codable, InBodyError: CustomError>(
        inBodyError: InBodyError.Type,
        _ target: ApiTarget,
        responseType: T.Type,
        decoder: JSONDecoder
    ) async throws -> T {
        capturedTargets.append(target)
        onRequest?(target)

        if responseDelayNanoseconds > .zero {
            try await Task.sleep(nanoseconds: responseDelayNanoseconds)
        }

        if let nextError {
            throw nextError
        }

        guard let data = nextResponseData else {
            throw MockError.missingResponseData
        }

        return try decoder.decode(T.self, from: data)
    }

    func request<InBodyError: CustomError>(
        inBodyError: InBodyError.Type,
        _ target: ApiTarget
    ) async throws {
        capturedTargets.append(target)
        onRequestWithoutResponse?(target)

        if let nextError {
            throw nextError
        }
    }
}
