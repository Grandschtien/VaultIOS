import Foundation
import NetworkClient

final class AsyncNetworkClientContractSpy: AsyncNetworkClient, @unchecked Sendable {
    enum SpyError: Error {
        case missingResponseData
    }

    var onRequest: ((ApiTarget) -> Void)?
    var onRequestWithoutResponse: ((ApiTarget) -> Void)?
    var nextError: Error?

    private let lock = NSLock()
    private var _nextResponseData: Data?
    private var _capturedTargets: [ApiTarget] = []

    var capturedTargets: [ApiTarget] {
        lock.withLock { _capturedTargets }
    }

    func setResponse(json: String) {
        lock.withLock {
            _nextResponseData = Data(json.utf8)
        }
    }

    func request<T: Codable, InBodyError: CustomError>(
        inBodyError: InBodyError.Type,
        _ target: ApiTarget,
        responseType: T.Type,
        decoder: JSONDecoder
    ) async throws -> T {
        lock.withLock {
            _capturedTargets.append(target)
        }

        onRequest?(target)

        if let nextError {
            throw nextError
        }

        let data = lock.withLock { _nextResponseData }
        guard let data else {
            throw SpyError.missingResponseData
        }

        return try decoder.decode(T.self, from: data)
    }

    func request<InBodyError: CustomError>(
        inBodyError: InBodyError.Type,
        _ target: ApiTarget
    ) async throws {
        lock.withLock {
            _capturedTargets.append(target)
        }

        onRequestWithoutResponse?(target)

        if let nextError {
            throw nextError
        }
    }
}

private extension NSLock {
    func withLock<T>(_ block: () -> T) -> T {
        lock()
        defer { unlock() }
        return block()
    }
}
