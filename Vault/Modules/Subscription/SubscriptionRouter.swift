// Created by Egor Shkarin 08.04.2026

import UIKit
import Foundation
import Nivelir

@MainActor
protocol SubscriptionRoutingLogic: Sendable {
    func close()
    func presentError(with text: String)
    func presentMessage(with text: String)
    func presentSuccess(with text: String)
    func openTermsOfUse()
    func openPrivacyPolicy()
}

final class SubscriptionRouter: SubscriptionRoutingLogic {
    private enum Constants {
        static let privacyPolicyURLString = "https://www.moneyvaultapp.com/privacy/"
        static let termsOfUseURLString = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
    }

    private let screenRouter: ScreenNavigator
    private let toastPresenter: ToastPresenting
    private let openURLHandler: @MainActor @Sendable (URL) -> Void

    weak var viewController: UIViewController?

    init(
        screenRouter: ScreenNavigator,
        toastPresenter: ToastPresenting,
        openURLHandler: @escaping @MainActor @Sendable (URL) -> Void = { url in
            UIApplication.shared.open(url)
        }
    ) {
        self.screenRouter = screenRouter
        self.toastPresenter = toastPresenter
        self.openURLHandler = openURLHandler
    }

    func close() {
        let container = viewController?.navigationController ?? viewController

        screenRouter.navigate(from: container) { route in
            route.dimiss()
        }
    }

    func presentError(with text: String) {
        toastPresenter.present(
            state: .error,
            title: SubscriptionToastMessageSanitizer.sanitize(text)
        )
    }

    func presentMessage(with text: String) {
        toastPresenter.present(
            state: .neutral,
            title: SubscriptionToastMessageSanitizer.sanitize(text)
        )
    }

    func presentSuccess(with text: String) {
        toastPresenter.present(
            state: .success,
            title: SubscriptionToastMessageSanitizer.sanitize(text)
        )
    }

    func openTermsOfUse() {
        openURL(Constants.termsOfUseURLString)
    }

    func openPrivacyPolicy() {
        openURL(Constants.privacyPolicyURLString)
    }
}

private extension SubscriptionRouter {
    func openURL(_ rawURL: String) {
        guard let url = URL(string: rawURL) else {
            return
        }

        openURLHandler(url)
    }
}
