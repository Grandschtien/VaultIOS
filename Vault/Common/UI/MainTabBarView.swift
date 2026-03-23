import UIKit
import SnapKit

final class MainTabBarView: UIView, LayoutScaleProviding {
    private(set) var viewModel: ViewModel = .init()
    private let centerActionButton = UIButton(type: .system)

    private var centerActionButtonSize: CGFloat { sizeXL }
    private var centerActionButtonOffset: CGFloat { spaceXS }
    private var centerActionSymbolSize: CGFloat { sizeM }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let buttonPoint = centerActionButton.convert(point, from: self)
        return centerActionButton.point(inside: buttonPoint, with: event)
    }

    func apply(_ viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    func applyAppearance(to tabBar: UITabBar) {
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = Asset.Colors.backgroundPrimary.color
        tabBarAppearance.shadowColor = Asset.Colors.textAndIconPlaceseholder.color.withAlphaComponent(0.2)

        [tabBarAppearance.stackedLayoutAppearance,
         tabBarAppearance.inlineLayoutAppearance,
         tabBarAppearance.compactInlineLayoutAppearance].forEach { itemAppearance in
            itemAppearance.normal.iconColor = Asset.Colors.textAndIconPlaceseholder.color
            itemAppearance.normal.titleTextAttributes = [
                .foregroundColor: Asset.Colors.textAndIconPlaceseholder.color,
                .font: Typography.typographyMedium14
            ]
            itemAppearance.selected.iconColor = Asset.Colors.interactiveElemetsPrimary.color
            itemAppearance.selected.titleTextAttributes = [
                .foregroundColor: Asset.Colors.interactiveElemetsPrimary.color,
                .font: Typography.typographyMedium14
            ]
        }

        tabBar.standardAppearance = tabBarAppearance
        tabBar.scrollEdgeAppearance = tabBarAppearance
        tabBar.unselectedItemTintColor = Asset.Colors.textAndIconPlaceseholder.color
        tabBar.tintColor = Asset.Colors.interactiveElemetsPrimary.color
        tabBar.isTranslucent = false

        tabBar.layer.shadowColor = UIColor.black.cgColor
        tabBar.layer.shadowOpacity = 0.06
        tabBar.layer.shadowOffset = CGSize(width: .zero, height: -spaceXXXS)
        tabBar.layer.shadowRadius = sizeXS
    }

    func attach(to containerView: UIView, tabBar: UITabBar) {
        if superview !== containerView {
            removeFromSuperview()
            containerView.addSubview(self)
            snp.makeConstraints {
                $0.edges.equalToSuperview()
            }
        }

        containerView.bringSubviewToFront(self)

        centerActionButton.snp.remakeConstraints {
            $0.centerX.equalTo(tabBar.snp.centerX)
            $0.centerY.equalTo(tabBar.snp.top).offset(centerActionButtonOffset)
            $0.width.height.equalTo(centerActionButtonSize)
        }
    }
}

private extension MainTabBarView {
    func setupView() {
        backgroundColor = .clear
        setupCenterActionButton()
    }

    func setupCenterActionButton() {
        addSubview(centerActionButton)

        centerActionButton.backgroundColor = Asset.Colors.interactiveElemetsPrimary.color
        centerActionButton.tintColor = Asset.Colors.textAndIconPrimaryInverted.color
        centerActionButton.layer.cornerRadius = sizeL
        centerActionButton.layer.shadowColor = Asset.Colors.interactiveElemetsPrimary.color.cgColor
        centerActionButton.layer.shadowOpacity = 0.35
        centerActionButton.layer.shadowOffset = CGSize(width: .zero, height: spaceXS)
        centerActionButton.layer.shadowRadius = sizeS
        centerActionButton.setImage(
            UIImage(
                systemName: "plus",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: centerActionSymbolSize, weight: .medium)
            ),
            for: .normal
        )
        centerActionButton.addTarget(self, action: #selector(handleTapCenterActionButton), for: .touchUpInside)
    }

    @objc
    func handleTapCenterActionButton() {
        viewModel.centerActionTapCommand.execute()
    }
}

extension MainTabBarView {
    struct ViewModel: Equatable {
        let centerActionTapCommand: Command

        init(
            centerActionTapCommand: Command = .nope
        ) {
            self.centerActionTapCommand = centerActionTapCommand
        }
    }
}
