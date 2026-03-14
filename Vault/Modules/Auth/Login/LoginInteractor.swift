// Created by Egor Shkarin 14.03.2026

import Foundation

protocol LoginBusinessLogic: Sendable {
    func fetchData() async
}

protocol LoginHandler: AnyObject, Sendable {}

actor LoginInteractor: LoginBusinessLogic {
    private let presenter: LoginPresentationLogic
    private let router: LoginRoutingLogic

    init(
        presenter: LoginPresentationLogic,
        router: LoginRoutingLogic
    ) {
        self.presenter = presenter
        self.router = router
    }

    func fetchData() async {}
}

private extension LoginInteractor {}

extension LoginInteractor: LoginHandler {}
