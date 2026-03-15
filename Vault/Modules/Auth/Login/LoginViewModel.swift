// Created by Egor Shkarin 14.03.2026

import UIKit

struct LoginViewModel: Equatable {
    let logo: UIImage
    let title: Label.LabelViewModel
    let subtitle: Label.LabelViewModel
    let emailField: TextField.ViewModel
    let passwordField: TextField.ViewModel
    let signInButton: Button.ButtonViewModel
    let privacyLabel: Label.LabelViewModel
    let termsLabel: Label.LabelViewModel
    let supportLabel: Label.LabelViewModel

    init(
        logo: UIImage = Asset.Icons.loginIcon.image,
        title: Label.LabelViewModel = .init(),
        subtitle: Label.LabelViewModel = .init(),
        emailField: TextField.ViewModel = .init(),
        passwordField: TextField.ViewModel = .init(),
        signInButton: Button.ButtonViewModel = .init(),
        privacyLabel: Label.LabelViewModel = .init(),
        termsLabel: Label.LabelViewModel = .init(),
        supportLabel: Label.LabelViewModel = .init()
    ) {
        self.logo = logo
        self.title = title
        self.subtitle = subtitle
        self.emailField = emailField
        self.passwordField = passwordField
        self.signInButton = signInButton
        self.privacyLabel = privacyLabel
        self.termsLabel = termsLabel
        self.supportLabel = supportLabel
    }
}
