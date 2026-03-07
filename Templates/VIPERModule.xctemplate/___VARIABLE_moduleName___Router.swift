// Created by Egor Shkarin ___DATE___

import UIKit
import Foundation
import Nivelir

@MainActor
protocol ___VARIABLE_moduleName___RoutingLogic: Sendable {}

final class ___VARIABLE_moduleName___Router: ___VARIABLE_moduleName___RoutingLogic {
    private let screenRouter: ScreenNavigator

    weak var viewController: UIViewController?

    init(screenRouter: ScreenNavigator) {
        self.screenRouter = screenRouter
    }
}
