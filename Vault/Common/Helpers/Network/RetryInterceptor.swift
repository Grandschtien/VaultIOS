//
//  RetryInterceptor.swift
//  Vault
//
//  Created by Егор Шкарин on 15.03.2026.
//

import Foundation
import Alamofire

final class RetryInterceptor: RequestInterceptor {
    private enum Constants {
        static let unauthorizedStatusCode = 401
        static let unprotectedPaths: Set<String> = [
            "/auth/login",
            "/auth/register",
            "/auth/refresh",
            "/auth/logout"
        ]
    }

    private let authSessionService: AuthSessionServiceProtocol

    init(authSessionService: AuthSessionServiceProtocol) {
        self.authSessionService = authSessionService
    }

    func adapt(
        _ urlRequest: URLRequest,
        for session: Session,
        completion: @escaping @Sendable (Result<URLRequest, any Error>) -> Void
    ) {
        completion(.success(urlRequest))
    }

    func retry(
        _ request: Request,
        for session: Session,
        dueTo error: any Error,
        completion: @escaping @Sendable (RetryResult) -> Void
    ) {
        guard request.response?.statusCode == Constants.unauthorizedStatusCode else {
            completion(.doNotRetry)
            return
        }

        guard isProtected(request) else {
            completion(.doNotRetry)
            return
        }

        guard request.retryCount == .zero else {
            completion(.doNotRetryWithError(error))
            return
        }

        Task {
            do {
                _ = try await authSessionService.refreshAccessToken()
                completion(.retry)
            } catch {
                completion(.doNotRetryWithError(error))
            }
        }
    }
}

private extension RetryInterceptor {
    func isProtected(_ request: Request) -> Bool {
        guard let path = request.request?.url?.path else {
            return false
        }

        return !Constants.unprotectedPaths.contains(path)
    }
}
