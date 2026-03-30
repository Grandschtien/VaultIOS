// Created by Egor Shkarin 29.03.2026

import UIKit
import Foundation
import Nivelir

@MainActor
protocol ProfileRoutingLogic: Sendable {}

final class ProfileRouter: ProfileRoutingLogic {
    private let screenRouter: ScreenNavigator

    weak var viewController: UIViewController?

    init(screenRouter: ScreenNavigator) {
        self.screenRouter = screenRouter
    }
}
