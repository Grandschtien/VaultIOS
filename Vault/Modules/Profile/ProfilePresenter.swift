// Created by Egor Shkarin 29.03.2026

import Foundation
internal import Combine

@MainActor
protocol ProfilePresentationLogic: Sendable {
    func presentFetchedData(_ data: ProfileFetchData)
}

final class ProfilePresenter: ProfilePresentationLogic {

    @Published
    private(set) var viewModel: ProfileViewModel

    weak var handler: ProfileHandler?

    init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
    }

    func presentFetchedData(_ data: ProfileFetchData) {}
}

private extension ProfilePresenter {}
