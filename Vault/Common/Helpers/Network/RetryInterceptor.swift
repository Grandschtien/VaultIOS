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
        retry(
            statusCode: request.response?.statusCode,
            path: request.request?.url?.path,
            retryCount: request.retryCount,
            dueTo: error,
            completion: completion
        )
    }

    func retry(
        statusCode: Int?,
        path: String?,
        retryCount: Int,
        dueTo error: any Error,
        completion: @escaping @Sendable (RetryResult) -> Void
    ) {
        guard statusCode == Constants.unauthorizedStatusCode else {
            completion(.doNotRetry)
            return
        }

        guard isProtected(path) else {
            completion(.doNotRetry)
            return
        }

        guard retryCount == .zero else {
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
    func isProtected(_ path: String?) -> Bool {
        guard let path else {
            return false
        }

        return !Constants.unprotectedPaths.contains(path)
    }
}
