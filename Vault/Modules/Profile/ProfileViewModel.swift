// Created by Egor Shkarin 29.03.2026

import Foundation
import UIKit

struct ProfileViewModel: Equatable {
    let navigationTitle: Label.LabelViewModel
    let isBackButtonHidden: Bool
    let saveCurrencyButton: SaveCurrencyButtonViewModel?
    let state: State

    init(
        navigationTitle: Label.LabelViewModel = .init(),
        isBackButtonHidden: Bool = false,
        saveCurrencyButton: SaveCurrencyButtonViewModel? = nil,
        state: State = .loading(.init())
    ) {
        self.navigationTitle = navigationTitle
        self.isBackButtonHidden = isBackButtonHidden
        self.saveCurrencyButton = saveCurrencyButton
        self.state = state
    }
}

extension ProfileViewModel {
    enum State: Equatable {
        case loading(Content)
        case loaded(Content)
        case error(FullScreenCommonErrorView.ViewModel)
    }
}

extension ProfileViewModel {
    struct Content: Equatable {
        let avatar: Avatar
        let name: Label.LabelViewModel
        let membership: Label.LabelViewModel
        let plan: PlanCard
        let generalSectionTitle: Label.LabelViewModel
        let rows: [GeneralRow]
        let logoutButton: Button.ButtonViewModel
        let version: Label.LabelViewModel
        let isSavingCurrency: Bool

        init(
            avatar: Avatar = .init(),
            name: Label.LabelViewModel = .init(),
            membership: Label.LabelViewModel = .init(),
            plan: PlanCard = .init(),
            generalSectionTitle: Label.LabelViewModel = .init(),
            rows: [GeneralRow] = [],
            logoutButton: Button.ButtonViewModel = .init(),
            version: Label.LabelViewModel = .init(),
            isSavingCurrency: Bool = false
        ) {
            self.avatar = avatar
            self.name = name
            self.membership = membership
            self.plan = plan
            self.generalSectionTitle = generalSectionTitle
            self.rows = rows
            self.logoutButton = logoutButton
            self.version = version
            self.isSavingCurrency = isSavingCurrency
        }
    }
}

extension ProfileViewModel {
    struct Avatar: Equatable {
        let initials: Label.LabelViewModel
        let backgroundColor: UIColor

        init(
            initials: Label.LabelViewModel = .init(),
            backgroundColor: UIColor = Asset.Colors.interactiveInputBackground.color
        ) {
            self.initials = initials
            self.backgroundColor = backgroundColor
        }
    }
}

extension ProfileViewModel {
    struct PlanCard: Equatable {
        let icon: UIImage?
        let title: Label.LabelViewModel
        let subtitle: Label.LabelViewModel
        let tapCommand: Command

        init(
            icon: UIImage? = nil,
            title: Label.LabelViewModel = .init(),
            subtitle: Label.LabelViewModel = .init(),
            tapCommand: Command = .nope
        ) {
            self.icon = icon
            self.title = title
            self.subtitle = subtitle
            self.tapCommand = tapCommand
        }
    }
}

extension ProfileViewModel {
    struct GeneralRow: Equatable {
        let icon: UIImage?
        let iconBackgroundColor: UIColor
        let title: Label.LabelViewModel
        let subtitle: Label.LabelViewModel
        let tapCommand: Command

        init(
            icon: UIImage? = nil,
            iconBackgroundColor: UIColor = Asset.Colors.interactiveInputBackground.color,
            title: Label.LabelViewModel = .init(),
            subtitle: Label.LabelViewModel = .init(),
            tapCommand: Command = .nope
        ) {
            self.icon = icon
            self.iconBackgroundColor = iconBackgroundColor
            self.title = title
            self.subtitle = subtitle
            self.tapCommand = tapCommand
        }
    }
}

extension ProfileViewModel {
    struct SaveCurrencyButtonViewModel: Equatable {
        let tapCommand: Command
        let isEnabled: Bool

        init(
            tapCommand: Command = .nope,
            isEnabled: Bool = true
        ) {
            self.tapCommand = tapCommand
            self.isEnabled = isEnabled
        }
    }
}
