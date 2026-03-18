// Created by Egor Shkarin 16.03.2026

import UIKit

struct RegistrationViewModel: Equatable {
    let navigationTitle: Label.LabelViewModel
    let stepLabel: Label.LabelViewModel
    let progress: ProgressViewModel
    let content: ContentViewModel
    let primaryButton: Button.ButtonViewModel
    let secondaryButton: Button.ButtonViewModel
    let isSecondaryButtonHidden: Bool

    init(
        navigationTitle: Label.LabelViewModel = .init(),
        stepLabel: Label.LabelViewModel = .init(),
        progress: ProgressViewModel = .init(),
        content: ContentViewModel = .account(.init()),
        primaryButton: Button.ButtonViewModel = .init(),
        secondaryButton: Button.ButtonViewModel = .init(),
        isSecondaryButtonHidden: Bool = true
    ) {
        self.navigationTitle = navigationTitle
        self.stepLabel = stepLabel
        self.progress = progress
        self.content = content
        self.primaryButton = primaryButton
        self.secondaryButton = secondaryButton
        self.isSecondaryButtonHidden = isSecondaryButtonHidden
    }
}

extension RegistrationViewModel {
    struct ProgressViewModel: Equatable {
        let value: CGFloat

        init(value: CGFloat = .zero) {
            self.value = value
        }
    }

    enum ContentViewModel: Equatable {
        case account(AccountViewModel)
        case name(NameViewModel)
        case currency(CurrencyViewModel)
    }

    struct AccountViewModel: Equatable {
        let title: Label.LabelViewModel
        let subtitle: Label.LabelViewModel
        let emailField: TextField.ViewModel
        let passwordField: TextField.ViewModel
        let confirmPasswordField: TextField.ViewModel

        init(
            title: Label.LabelViewModel = .init(),
            subtitle: Label.LabelViewModel = .init(),
            emailField: TextField.ViewModel = .init(),
            passwordField: TextField.ViewModel = .init(),
            confirmPasswordField: TextField.ViewModel = .init()
        ) {
            self.title = title
            self.subtitle = subtitle
            self.emailField = emailField
            self.passwordField = passwordField
            self.confirmPasswordField = confirmPasswordField
        }
    }

    struct NameViewModel: Equatable {
        let title: Label.LabelViewModel
        let subtitle: Label.LabelViewModel
        let nameField: TextField.ViewModel

        init(
            title: Label.LabelViewModel = .init(),
            subtitle: Label.LabelViewModel = .init(),
            nameField: TextField.ViewModel = .init()
        ) {
            self.title = title
            self.subtitle = subtitle
            self.nameField = nameField
        }
    }

    struct CurrencyViewModel: Equatable {
        let title: Label.LabelViewModel
        let searchField: TextField.ViewModel
        let errorLabel: Label.LabelViewModel?
        let popularSectionTitle: Label.LabelViewModel?
        let otherSectionTitle: Label.LabelViewModel?
        let popularRows: [CurrencyRowViewModel]
        let otherRows: [CurrencyRowViewModel]

        init(
            title: Label.LabelViewModel = .init(),
            searchField: TextField.ViewModel = .init(),
            errorLabel: Label.LabelViewModel? = nil,
            popularSectionTitle: Label.LabelViewModel? = nil,
            otherSectionTitle: Label.LabelViewModel? = nil,
            popularRows: [CurrencyRowViewModel] = [],
            otherRows: [CurrencyRowViewModel] = []
        ) {
            self.title = title
            self.searchField = searchField
            self.errorLabel = errorLabel
            self.popularSectionTitle = popularSectionTitle
            self.otherSectionTitle = otherSectionTitle
            self.popularRows = popularRows
            self.otherRows = otherRows
        }
    }

    struct CurrencyRowViewModel: Equatable {
        let title: Label.LabelViewModel
        let subtitle: Label.LabelViewModel
        let isSelected: Bool
        let tapCommand: Command

        init(
            title: Label.LabelViewModel = .init(),
            subtitle: Label.LabelViewModel = .init(),
            isSelected: Bool = false,
            tapCommand: Command = .nope
        ) {
            self.title = title
            self.subtitle = subtitle
            self.isSelected = isSelected
            self.tapCommand = tapCommand
        }
    }
}
