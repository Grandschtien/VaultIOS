//
//  AuthAPI.swift
//  Vault
//
//  Created by Егор Шкарин on 14.03.2026.
//

import Foundation
import Alamofire
import NetworkClient

enum AuthAPI: ApiTarget, Sendable {
    case login(LoginRequestDTO)
    case register(RegisterRequestDTO)
    case forgotPassword(ForgotPasswordRequestDTO)
    case resetPassword(ResetPasswordRequestDTO)
    case refresh(AuthTokenRequestDTO)
    case logout(AuthTokenRequestDTO)
    
    var host: String {
        MainAPIConfiguration.host
    }
    
    var path: String {
        switch self {
        case .login:
            "/auth/login"
        case .register:
            "/auth/register"
        case .forgotPassword:
            "/auth/password/forgot"
        case .resetPassword:
            "/auth/password/reset"
        case .refresh:
            "/auth/refresh"
        case .logout:
            "/auth/logout"
        }
    }
    
    var method: HTTPMethod {
        .post
    }
    
    var headers: [String : String] { [:] }
    
    var timeoutInterval: TimeInterval {
        MainAPIConfiguration.timeoutInterval
    }
    
    var httpBody: Data?  { nil }
    
    var requestType: RequestType {
        switch self {
        case let .login(dto):
            .custonJSON(data: dto, encoder: JSONCoder.encoder)
        case let .register(dto):
            .custonJSON(data: dto, encoder: JSONCoder.encoder)
        case let .forgotPassword(dto):
            .custonJSON(data: dto, encoder: JSONCoder.encoder)
        case let .resetPassword(dto):
            .custonJSON(data: dto, encoder: JSONCoder.encoder)
        case let .refresh(dto):
            .custonJSON(data: dto, encoder: JSONCoder.encoder)
        case let .logout(dto):
            .custonJSON(data: dto, encoder: JSONCoder.encoder)
        }
    }

    var url: URL {
        MainAPIConfiguration.url(path: path)
    }
}
