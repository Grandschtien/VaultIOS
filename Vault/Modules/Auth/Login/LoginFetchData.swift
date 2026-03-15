// Created by Egor Shkarin 14.03.2026

import Foundation

struct LoginFetchData: Sendable {
    let loadingState: LoadingStatus
    
    init(loadingState: LoadingStatus = .idle) {
        self.loadingState = loadingState
    }
}
