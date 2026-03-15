// Created by Egor Shkarin 14.03.2026

import Foundation

struct LoginFetchData: Sendable {
    let loadingState: LoadingStatus
    let email: String
    let password: String

    init(
        loadingState: LoadingStatus = .idle,
        email: String = "",
        password: String = ""
    ) {
        self.loadingState = loadingState
        self.email = email
        self.password = password
    }
}
