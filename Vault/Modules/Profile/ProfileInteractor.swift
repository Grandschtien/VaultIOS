// Created by Egor Shkarin 29.03.2026

import Foundation

protocol ProfileBusinessLogic: Sendable {
    func fetchData() async
}

protocol ProfileHandler: AnyObject, Sendable {}

actor ProfileInteractor: ProfileBusinessLogic {
    private let presenter: ProfilePresentationLogic
    private let router: ProfileRoutingLogic

    init(
        presenter: ProfilePresentationLogic,
        router: ProfileRoutingLogic
    ) {
        self.presenter = presenter
        self.router = router
    }

    func fetchData() async {}
}

private extension ProfileInteractor {}

extension ProfileInteractor: ProfileHandler {}
