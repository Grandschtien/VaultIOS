// Created by Egor Shkarin 14.03.2026

import UIKit
import Foundation
import Nivelir

@MainActor
protocol LoginRoutingLogic: Sendable {
    func openRegistration()
    func openForgetPasswordScreen()
    func presentError(with text: String)
}

final class LoginRouter: LoginRoutingLogic {
    private let screenRouter: ScreenNavigator
    private let toastPresenter: ToastPresenting

    weak var viewController: UIViewController?

    init(
        screenRouter: ScreenNavigator,
        toastPresenter: ToastPresenting
    ) {
        self.screenRouter = screenRouter
        self.toastPresenter = toastPresenter
    }

    func openRegistration() {
        
    }
    
    func openForgetPasswordScreen() {
        
    }
    
    func presentError(with text: String) {
        toastPresenter.present(state: .error, title: text)
    }
}
