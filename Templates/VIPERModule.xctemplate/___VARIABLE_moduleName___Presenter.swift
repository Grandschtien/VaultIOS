// Created by Egor Shkarin ___DATE___

import Foundation
internal import Combine

@MainActor
protocol ___VARIABLE_moduleName___PresentationLogic: Sendable {
    func presentFetchedData(_ data: ___VARIABLE_moduleName___FetchData)
}

final class ___VARIABLE_moduleName___Presenter: ___VARIABLE_moduleName___PresentationLogic {

    @Published
    private(set) var viewModel: ___VARIABLE_moduleName___ViewModel

    weak var handler: ___VARIABLE_moduleName___Handler?

    init(viewModel: ___VARIABLE_moduleName___ViewModel) {
        self.viewModel = viewModel
    }

    func presentFetchedData(_ data: ___VARIABLE_moduleName___FetchData) {}
}

private extension ___VARIABLE_moduleName___Presenter {}
