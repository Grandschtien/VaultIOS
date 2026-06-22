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
    private let pendingRouteStore: PendingVaultRouteStoring
    private let widgetEntryDestinationResolver: VaultWidgetEntryDestinationResolving
    private let tabBarView = MainTabBarView()
    private var logoutObserver: NSObjectProtocol?
    private var pendingRouteObserver: NSObjectProtocol?
    private var currencyDidChangeObserver: NSObjectProtocol?
    private var profileButtonSize: CGFloat { sizeL }
    private var profileIconSize: CGFloat { sizeS }

    init(
        screenNavigator: ScreenNavigator,
        context: MainFlowContext,
        pendingRouteStore: PendingVaultRouteStoring,
        widgetEntryDestinationResolver: VaultWidgetEntryDestinationResolving
    ) {
        self.screenNavigator = screenNavigator
        self.context = context
        self.pendingRouteStore = pendingRouteStore
        self.widgetEntryDestinationResolver = widgetEntryDestinationResolver
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
        observePendingRouteEvents()
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        handlePendingRouteIfNeeded()
    }

    deinit {
        if let logoutObserver {
            NotificationCenter.default.removeObserver(logoutObserver)
        }

        if let pendingRouteObserver {
            NotificationCenter.default.removeObserver(pendingRouteObserver)
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
        let analyticsController = AnalyticsFactory(context: context).build(
            navigator: screenNavigator
        )
        homeController.title = L10n.mainOverviewTitle
        analyticsController.title = L10n.mainTabStats

        homeController.tabBarItem = UITabBarItem(
            title: L10n.mainTabHome,
            image: houseImage,
            selectedImage: houseFillImage
        )

        analyticsController.tabBarItem = UITabBarItem(
            title: L10n.mainTabStats,
            image: chartPieImage,
            selectedImage: chartPieFillImage
        )

        viewControllers = [
            makeNavigationController(
                rootController: homeController,
                showsProfileButton: true
            ),
            makeNavigationController(
                rootController: analyticsController,
                showsProfileButton: true
            )
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

    func observePendingRouteEvents() {
        pendingRouteObserver = NotificationCenter.default.addObserver(
            forName: .pendingVaultRouteDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handlePendingRouteIfNeeded()
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

    func makeNavigationController(
        rootController: UIViewController,
        showsProfileButton: Bool
    ) -> UINavigationController {
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
        rootController.navigationItem.rightBarButtonItem = showsProfileButton
            ? UIBarButtonItem(customView: makeProfileButton())
            : nil

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

    func handlePendingRouteIfNeeded() {
        guard view.window != nil,
              let route = pendingRouteStore.consume() else {
            return
        }

        switch route {
        case .home:
            routeToHome()
        case .aiEntry:
            openAIEntryFromWidget()
        }
    }

    func routeToHome() {
        let resetHomeRoot = { [weak self] in
            guard let self else {
                return
            }

            self.selectedIndex = Constants.homeTabIndex
            (self.selectedViewController as? UINavigationController)?
                .popToRootViewController(animated: false)
        }

        guard presentedViewController != nil else {
            resetHomeRoot()
            return
        }

        dismiss(animated: true) {
            resetHomeRoot()
        }
    }

    func openAIEntryFromWidget() {
        Task { [weak self] in
            guard let self else {
                return
            }

            let destination = await self.widgetEntryDestinationResolver.resolveDestination()
            await MainActor.run {
                self.presentWidgetEntry(destination)
            }
        }
    }

    func presentWidgetEntry(_ destination: VaultWidgetEntryDestination) {
        let presentEntry = { [weak self] in
            guard let self else {
                return
            }

            self.screenNavigator.navigate(from: self) { route in
                switch destination {
                case .aiEntry:
                    route.present(
                        ExpenseAIEntryFactory(context: self.context)
                            .withBottomSheet(
                                .init(
                                    detents: [.content],
                                    prefferedGrabberForMaximumDetentValue: .default
                                )
                            )
                    )
                case .manualEntry:
                    route.present(
                        ExpenseManualEntryFactory(context: self.context)
                            .withBottomSheet(
                                .init(
                                    detents: [.content],
                                    prefferedGrabberForMaximumDetentValue: .default
                                )
                            )
                    )
                }
            }
        }

        guard presentedViewController == nil else {
            dismiss(animated: true) {
                presentEntry()
            }
            return
        }

        presentEntry()
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
