// Created by Egor Shkarin 14.03.2026

import Foundation
@preconcurrency import NetworkClient

protocol LoginBusinessLogic: Sendable {
    func fetchData() async
}

protocol LoginHandler: AnyObject, Sendable {
    func handleSignInDidTap() async
    func handleSignUpDidTap() async
    func handleForgotDidTap() async
}

actor LoginInteractor: LoginBusinessLogic {
    private let networkClient: NetworkClient
    private let presenter: LoginPresentationLogic
    private let router: LoginRoutingLogic

    init(
        networkClient: NetworkClient,
        presenter: LoginPresentationLogic,
        router: LoginRoutingLogic
    ) {
        self.networkClient = networkClient
        self.presenter = presenter
        self.router = router
    }

    func fetchData() async {
        
    }
}

private extension LoginInteractor {
    
}

extension LoginInteractor: LoginHandler {
    func handleSignInDidTap() async {
        
    }
    
    func handleSignUpDidTap() async {
        
    }
    
    func handleForgotDidTap() async {
        
    }
}
