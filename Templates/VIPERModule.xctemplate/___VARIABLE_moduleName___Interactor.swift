// Created by Egor Shkarin ___DATE___

import Foundation

protocol ___VARIABLE_moduleName___BusinessLogic: Sendable {
    func fetchData() async
}

protocol ___VARIABLE_moduleName___Handler: AnyObject, Sendable {}

actor ___VARIABLE_moduleName___Interactor: ___VARIABLE_moduleName___BusinessLogic {
    private let presenter: ___VARIABLE_moduleName___PresentationLogic
    private let router: ___VARIABLE_moduleName___RoutingLogic

    init(
        presenter: ___VARIABLE_moduleName___PresentationLogic,
        router: ___VARIABLE_moduleName___RoutingLogic
    ) {
        self.presenter = presenter
        self.router = router
    }

    func fetchData() async {}
}

private extension ___VARIABLE_moduleName___Interactor {}

extension ___VARIABLE_moduleName___Interactor: ___VARIABLE_moduleName___Handler {}
