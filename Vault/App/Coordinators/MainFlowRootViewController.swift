//
//  MainFlowRootViewController.swift
//  Vault
//
//  Created by Егор Шкарин on 17.03.2026.
//

import UIKit
import Nivelir

final class MainFlowRootViewController: UITabBarController, Screen, LayoutScaleProviding, ImageProviding {
    private enum Constants {
        static let homeTabIndex: Int = 0
    }

    private let screenNavigator: ScreenNavigator
    private let context: MainFlowContext
    private let tabBarView = MainTabBarView()
    private var logoutObserver: NSObjectProtocol?
    private var currencyDidChangeObserver: NSObjectProtocol?
    private var profileButtonSize: CGFloat { sizeL }
    private var profileIconSize: CGFloat { sizeS }

    init(
        screenNavigator: ScreenNavigator,
        context: MainFlowContext
    ) {
        self.screenNavigator = screenNavigator
        self.context = context
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        observeLogoutEvents()
        observeCurrencyChangeEvents()

        setupTabs()
        tabBarView.applyAppearance(to: tabBar)
        tabBarView.attach(to: view, tabBar: tabBar)
        tabBarView.apply(
            .init(
                centerActionTapCommand: Command { [weak self] in
                    self?.openAddExpenseChooser()
                }
            )
        )

        selectedIndex = Constants.homeTabIndex
    }

    deinit {
        if let logoutObserver {
            NotificationCenter.default.removeObserver(logoutObserver)
        }

        if let currencyDidChangeObserver {
            NotificationCenter.default.removeObserver(currencyDidChangeObserver)
        }
    }
}

private extension MainFlowRootViewController {
    func setupTabs() {
        let homeController = MainFactory(context: context).build(
            navigator: screenNavigator
        )
        let statsController = MainFlowPlaceholderViewController(titleText: L10n.mainTabStats)
        homeController.title = L10n.mainOverviewTitle

        homeController.tabBarItem = UITabBarItem(
            title: L10n.mainTabHome,
            image: houseImage,
            selectedImage: houseFillImage
        )

        statsController.tabBarItem = UITabBarItem(
            title: L10n.mainTabStats,
            image: chartPieImage,
            selectedImage: chartPieFillImage
        )

        viewControllers = [
            makeNavigationController(rootController: homeController),
            makeNavigationController(rootController: statsController)
        ]
    }

    func observeLogoutEvents() {
        logoutObserver = NotificationCenter.default.addObserver(
            forName: .authSessionDidLogout,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else {
                return
            }

            Task {
                await self.context.repository.clearSession()
            }
        }
    }

    func observeCurrencyChangeEvents() {
        currencyDidChangeObserver = NotificationCenter.default.addObserver(
            forName: .profileCurrencyDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self,
                  let payload = notification.object as? ProfileCurrencyDidChangePayload else {
                return
            }

            Task {
                await self.context.repository.handleCurrencyDidChange(payload)
            }
        }
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

    func openAddExpenseChooser() {
        screenNavigator.navigate(from: self) { route in
            route
                .present(
                    ExpenseEntryChooserFactory(
                        context: context
                    ).withBottomSheet(
                        .init(
                            detents: [.content],
                            prefferedGrabberForMaximumDetentValue: .default
                        )
                    )
                )
        }
    }

    func makeProfileButton() -> UIButton {
        let button = UIButton(type: .system)
        button.frame = CGRect(
            x: .zero,
            y: .zero,
            width: profileButtonSize,
            height: profileButtonSize
        )
        button.layer.cornerRadius = sizeS
        button.clipsToBounds = true
        button.backgroundColor = Asset.Colors.interactiveInputBackground.color
        button.tintColor = Asset.Colors.textAndIconSecondary.color
        button.setImage(
            personCropCircleImage(pointSize: profileIconSize, weight: .regular),
            for: .normal
        )
        button.accessibilityLabel = L10n.mainProfileAccessibilityLabel
        button.addTarget(self, action: #selector(handleTapProfileButton), for: .touchUpInside)

        return button
    }

    @objc
    func handleTapProfileButton() {
        screenNavigator.navigate(to: { route in
            route
                .top(.stack)
                .push(ProfileFactory())
        })
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
