// Created by Egor Shkarin 14.03.2026

import Foundation
internal import Combine

@MainActor
protocol LoginPresentationLogic: Sendable {
    func presentFetchedData(_ data: LoginFetchData)
}

final class LoginPresenter: LoginPresentationLogic {

    @Published
    private(set) var viewModel: LoginViewModel

    weak var handler: LoginHandler?

    init(viewModel: LoginViewModel) {
        self.viewModel = viewModel
    }

    func presentFetchedData(_ data: LoginFetchData) {}
}

private extension LoginPresenter {}
