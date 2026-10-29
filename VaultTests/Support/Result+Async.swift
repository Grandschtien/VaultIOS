import Foundation

extension Result where Failure == Error {
    init(catching body: () async throws -> Success) async {
        do {
            self = .success(try await body())
        } catch {
            self = .failure(error)
        }
    }

    var failure: Failure? {
        guard case let .failure(error) = self else {
            return nil
        }

        return error
    }
}
