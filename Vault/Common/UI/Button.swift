//
//  Button.swift
//  Vault
//
//  Created by Егор Шкарин on 09.03.2026.
//

import UIKit
import SnapKit

final class Button: UIButton, LayoutScaleProviding {
    private enum Constants {
        static let iconTextSpacing: CGFloat = 8
        static let defaultHeight: CGFloat = 56
        static let defaultCornerRadius: CGFloat = 24
        static let pressedScale: CGFloat = 0.96
        static let pressAnimationDuration: TimeInterval = 0.12
        static let releaseAnimationDuration: TimeInterval = 0.38
        static let releaseSpringDamping: CGFloat = 0.45
        static let releaseSpringVelocity: CGFloat = 2
    }

    private(set) var viewModel: ButtonViewModel = .init()
    private let rootStack = UIStackView()
    private let centerStack = UIStackView()
    private let leftIconView = UIImageView()
    private let titleTextLabel = UILabel()
    private let rightIconView = UIImageView()
    private let loaderView = UIActivityIndicatorView(style: .medium)
    private var heightConstraint: Constraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupContent()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(_ viewModel: ButtonViewModel) {
        self.viewModel = viewModel

        directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: spaceS,
            leading: spaceM,
            bottom: spaceS,
            trailing: spaceM
        )
        backgroundColor = viewModel.backgroundColor
        clipsToBounds = true
        isEnabled = viewModel.isEnabled && !viewModel.isLoading
        alpha = viewModel.isEnabled ? 1 : 0.6
        heightConstraint?.update(offset: viewModel.height)
        layer.cornerRadius = viewModel.cornerRadius

        titleTextLabel.text = viewModel.title
        titleTextLabel.font = viewModel.font
        titleTextLabel.textColor = viewModel.titleColor
    
        applyIcon(
            image: viewModel.leftIcon,
            imageView: leftIconView,
            tintColor: viewModel.iconTintColor ?? viewModel.titleColor
        )
        applyIcon(
            image: viewModel.rightIcon,
            imageView: rightIconView,
            tintColor: viewModel.iconTintColor ?? viewModel.titleColor
        )
        updateLoadingState(for: viewModel)

        if !viewModel.isEnabled || viewModel.isLoading {
            transform = .identity
        }
    }

    @objc
    private func handleTouchDown() {
        guard viewModel.isEnabled, !viewModel.isLoading else { return }

        UIView.animate(withDuration: Constants.pressAnimationDuration) {
            self.transform = CGAffineTransform(scaleX: Constants.pressedScale, y: Constants.pressedScale)
        }
    }

    @objc
    private func handleTouchUp() {
        guard viewModel.isEnabled, !viewModel.isLoading else { return }

        UIView.animate(
            withDuration: Constants.releaseAnimationDuration,
            delay: 0,
            usingSpringWithDamping: Constants.releaseSpringDamping,
            initialSpringVelocity: Constants.releaseSpringVelocity,
            options: [.allowUserInteraction, .beginFromCurrentState]
        ) {
            self.transform = .identity
        }
    }

    @objc
    private func handleTap() {
        guard viewModel.isEnabled, !viewModel.isLoading else { return }
        executeAfterDismissingKeyboard(viewModel.tapCommand)
    }

    private func setupContent() {
        contentHorizontalAlignment = .fill
        contentVerticalAlignment = .fill

        rootStack.axis = .vertical
        rootStack.alignment = .center
        rootStack.distribution = .fill
        rootStack.spacing = Constants.iconTextSpacing
        centerStack.axis = .horizontal
        centerStack.alignment = .center
        centerStack.distribution = .fill
        centerStack.spacing = Constants.iconTextSpacing

        leftIconView.contentMode = .scaleAspectFit
        rightIconView.contentMode = .scaleAspectFit
        [leftIconView, rightIconView].forEach {
            $0.setContentCompressionResistancePriority(.required, for: .horizontal)
            $0.setContentHuggingPriority(.required, for: .horizontal)
        }

        titleTextLabel.textAlignment = .center
        titleTextLabel.numberOfLines = 1
        titleTextLabel.lineBreakMode = .byTruncatingTail
        titleTextLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        addSubview(rootStack)

        rootStack.addArrangedSubview(centerStack)
        rootStack.addArrangedSubview(loaderView)

        centerStack.addArrangedSubview(leftIconView)
        centerStack.addArrangedSubview(titleTextLabel)
        centerStack.addArrangedSubview(rightIconView)

        rootStack.snp.makeConstraints { make in
            make.top.bottom.equalTo(layoutMarginsGuide)
            make.leading.greaterThanOrEqualTo(layoutMarginsGuide)
            make.trailing.lessThanOrEqualTo(layoutMarginsGuide)
            make.centerX.equalToSuperview()
        }
        
        snp.makeConstraints {
            heightConstraint = $0.height.equalTo(Constants.defaultHeight).constraint
        }

        layer.cornerRadius = Constants.defaultCornerRadius

        
        rootStack.isUserInteractionEnabled = false
        titleTextLabel.isUserInteractionEnabled = false
        loaderView.isHidden = true

        addTarget(self, action: #selector(handleTouchDown), for: .touchDown)
        addTarget(self, action: #selector(handleTouchDown), for: .touchDragEnter)
        addTarget(self, action: #selector(handleTouchUp), for: .touchUpInside)
        addTarget(self, action: #selector(handleTouchUp), for: .touchUpOutside)
        addTarget(self, action: #selector(handleTouchUp), for: .touchDragExit)
        addTarget(self, action: #selector(handleTouchUp), for: .touchCancel)
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }

    private func updateLoadingState(for viewModel: ButtonViewModel) {
        let isLoading = viewModel.isLoading
        centerStack.isHidden = isLoading
        loaderView.isHidden = !isLoading
        loaderView.color = viewModel.iconTintColor ?? viewModel.titleColor

        if isLoading {
            loaderView.startAnimating()
        } else {
            loaderView.stopAnimating()
        }
    }

    private func applyIcon(image: UIImage?, imageView: UIImageView, tintColor: UIColor) {
        guard let image else {
            imageView.image = nil
            imageView.isHidden = true
            return
        }

        imageView.image = image
        imageView.tintColor = tintColor
        imageView.isHidden = false
    }
}

extension Button {
    struct ButtonViewModel: Equatable {
        let title: String
        let titleColor: UIColor
        let backgroundColor: UIColor
        let font: UIFont
        let isEnabled: Bool
        let isLoading: Bool
        let tapCommand: Command
        let leftIcon: UIImage?
        let rightIcon: UIImage?
        let iconTintColor: UIColor?
        let height: CGFloat
        let cornerRadius: CGFloat

        init(
            title: String = "",
            titleColor: UIColor = .textAndIconPrimaryInverted,
            backgroundColor: UIColor = .backgroundPrimary,
            font: UIFont = Typography.regular16,
            isEnabled: Bool = true,
            isLoading: Bool = false,
            tapCommand: Command = .nope,
            leftIcon: UIImage? = nil,
            rightIcon: UIImage? = nil,
            iconTintColor: UIColor? = nil,
            height: CGFloat = Constants.defaultHeight,
            cornerRadius: CGFloat = Constants.defaultCornerRadius
        ) {
            self.title = title
            self.titleColor = titleColor
            self.backgroundColor = backgroundColor
            self.font = font
            self.isEnabled = isEnabled
            self.isLoading = isLoading
            self.tapCommand = tapCommand
            self.leftIcon = leftIcon
            self.rightIcon = rightIcon
            self.iconTintColor = iconTintColor
            self.height = height
            self.cornerRadius = cornerRadius
        }
    }
}
