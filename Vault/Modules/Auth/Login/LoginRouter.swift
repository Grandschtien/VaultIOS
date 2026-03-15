// Created by Egor Shkarin 14.03.2026

import UIKit
import Foundation
import Nivelir

@MainActor
protocol LoginRoutingLogic: Sendable {
    func openRegistration()
    func openForgetPasswordScreen()
}

final class LoginRouter: LoginRoutingLogic {
    private let screenRouter: ScreenNavigator

    weak var viewController: UIViewController?

    init(screenRouter: ScreenNavigator) {
        self.screenRouter = screenRouter
    }

    func openRegistration() {
        
    }
    
    func openForgetPasswordScreen() {
        
    }
}
