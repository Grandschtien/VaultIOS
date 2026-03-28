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
    case refresh(AuthTokenRequestDTO)
    
    var host: String {
        return "localhost"
    }
    
    var path: String {
        switch self {
        case .login:
            "/auth/login"
        case .register:
            "/auth/register"
        case .refresh:
            "/auth/refresh"
        }
    }
    
    var method: HTTPMethod {
        .post
    }
    
    var headers: [String : String] { [:] }
    
    var timeoutInterval: TimeInterval { 30 }
    
    var httpBody: Data?  { nil }
    
    var requestType: RequestType {
        switch self {
        case let .login(dto):
            .custonJSON(data: dto, encoder: JSONCoder.encoder)
        case let .register(dto):
            .custonJSON(data: dto, encoder: JSONCoder.encoder)
        case let .refresh(dto):
            .custonJSON(data: dto, encoder: JSONCoder.encoder)
        }
    }
    
    // Temp before real server
    var url: URL {
        var components = URLComponents()
        
        components.host = host
        components.port = 8080
        components.scheme = "https"
        components.path = path

        return components.url!
    }
}
