// Created by Codex on 27.03.2026

import UIKit
import Foundation
import Nivelir

@MainActor
protocol CategoriesListRoutingLogic: Sendable {}

final class CategoriesListRouter: CategoriesListRoutingLogic {
    private let screenRouter: ScreenNavigator

    weak var viewController: UIViewController?

    init(screenRouter: ScreenNavigator) {
        self.screenRouter = screenRouter
    }
}
