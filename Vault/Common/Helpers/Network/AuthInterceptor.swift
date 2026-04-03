//
//  AuthInterceptor.swift
//  Vault
//
//  Created by Егор Шкарин on 15.03.2026.
//

import Foundation
import Alamofire

final class AuthInterceptor: RequestAdapter {
    private enum Constants {
        static let authHeaderField = "Authorization"
        static let authHeaderPrefix = "Bearer "
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
        guard isProtected(urlRequest) else {
            completion(.success(urlRequest))
            return
        }

        Task {
            guard let accessToken = await authSessionService.accessToken(), !accessToken.isEmpty else {
                completion(.success(urlRequest))
                return
            }

            var adaptedRequest = urlRequest
            adaptedRequest.setValue(
                Constants.authHeaderPrefix + accessToken,
                forHTTPHeaderField: Constants.authHeaderField
            )
            completion(.success(adaptedRequest))
        }
    }
}

private extension AuthInterceptor {
    func isProtected(_ request: URLRequest) -> Bool {
        guard let path = request.url?.path else {
            return false
        }

        return !Constants.unprotectedPaths.contains(path)
    }
}
