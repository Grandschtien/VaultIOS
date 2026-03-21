//
//  MainFlowRootViewController.swift
//  Vault
//
//  Created by Егор Шкарин on 17.03.2026.
//

import UIKit
import Nivelir

final class MainFlowRootViewController: UITabBarController, Screen, LayoutScaleProviding {
    private enum Constants {
        static let centerTabIndex: Int = 1
    }

    private let tabBarView = MainTabBarView()
    private var profileButtonSize: CGFloat { sizeL + sizeXS }
    private var profileIconSize: CGFloat { sizeM - spaceXXS }

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self

        setupTabs()
        tabBarView.applyAppearance(to: tabBar)
        tabBarView.attach(to: view, tabBar: tabBar)
        tabBarView.apply(
            .init(
                centerActionTapCommand: Command { [weak self] in
                    self?.selectedIndex = Constants.centerTabIndex
                }
            )
        )

        selectedIndex = Constants.centerTabIndex
    }
}

private extension MainFlowRootViewController {
    func setupTabs() {
        let homeController = MainFlowPlaceholderViewController(titleText: L10n.mainTabHome)
        let centerController = MainFlowPlaceholderViewController(titleText: L10n.mainAddExpenseTitle)
        let statsController = MainFlowPlaceholderViewController(titleText: L10n.mainTabStats)

        homeController.tabBarItem = UITabBarItem(
            title: L10n.mainTabHome,
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill")
        )

        centerController.tabBarItem = UITabBarItem(
            title: nil,
            image: nil,
            selectedImage: nil
        )

        statsController.tabBarItem = UITabBarItem(
            title: L10n.mainTabStats,
            image: UIImage(systemName: "chart.pie"),
            selectedImage: UIImage(systemName: "chart.pie.fill")
        )

        viewControllers = [
            makeNavigationController(rootController: homeController),
            makeNavigationController(rootController: centerController),
            makeNavigationController(rootController: statsController)
        ]
    }

    func makeNavigationController(rootController: UIViewController) -> UINavigationController {
        let navigationController = UINavigationController(rootViewController: rootController)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = Asset.Colors.backgroundPrimary.color
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [
            .foregroundColor: Asset.Colors.textAndIconPrimary.color,
            .font: Typography.typographyBold20
        ]

        navigationController.navigationBar.standardAppearance = appearance
        navigationController.navigationBar.scrollEdgeAppearance = appearance
        navigationController.navigationBar.compactAppearance = appearance
        navigationController.navigationBar.tintColor = Asset.Colors.textAndIconPrimary.color
        navigationController.navigationBar.prefersLargeTitles = false

        rootController.navigationItem.largeTitleDisplayMode = .never
        rootController.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: makeProfileButton())

        return navigationController
    }

    func makeProfileButton() -> UIButton {
        let button = UIButton(type: .system)
        button.frame = CGRect(
            x: .zero,
            y: .zero,
            width: profileButtonSize,
            height: profileButtonSize
        )
        button.layer.cornerRadius = profileButtonSize / 2
        button.clipsToBounds = true
        button.backgroundColor = Asset.Colors.interactiveInputBackground.color
        button.tintColor = Asset.Colors.textAndIconSecondary.color
        button.setImage(
            UIImage(
                systemName: "person.crop.circle",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: profileIconSize, weight: .regular)
            ),
            for: .normal
        )
        button.accessibilityLabel = L10n.mainProfileAccessibilityLabel

        return button
    }
}

extension MainFlowRootViewController: UITabBarControllerDelegate {}

private final class MainFlowPlaceholderViewController: UIViewController {
    init(titleText: String) {
        super.init(nibName: nil, bundle: nil)
        title = titleText
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Asset.Colors.backgroundPrimary.color
    }
}
