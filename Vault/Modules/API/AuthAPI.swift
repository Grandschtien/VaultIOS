//
//  AuthAPI.swift
//  Vault
//
//  Created by Егор Шкарин on 14.03.2026.
//

import Foundation
import Alamofire
import NetworkClient

enum AuthAPI: ApiTarget {
    case login(LoginRequestDTO)
    case register
    case refresh
    
    var host: String {
        return "https://localhost:8080"
    }
    
    var path: String {
        switch self {
        case .login:
            "/auth/register"
        case .register:
            "/auth/login"
        case .refresh:
            "/auth/refresh"
        }
    }
    
    var method: HTTPMethod {
        .post
    }
    
    var headers: [String : String] {
        [:]
    }
    
    var timeoutInterval: TimeInterval {
        30
    }
    
    var httpBody: Data?  {
        nil
    }
    
    var requestType: RequestType {
        switch self {
        case let .login(dto):
            .custonJSON(data: dto, encoder: JSONCoder.encoder)
        case .register:
            .plain
        case .refresh:
            .plain
        }
    }
}
