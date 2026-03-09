//
//  Button.swift
//  Vault
//
//  Created by Егор Шкарин on 09.03.2026.
//

import UIKit
import SnapKit

final class Button: UIButton {
    private enum Constants {
        static let iconTextSpacing: CGFloat = 8
        static let pressedScale: CGFloat = 0.96
        static let pressAnimationDuration: TimeInterval = 0.12
        static let releaseAnimationDuration: TimeInterval = 0.38
        static let releaseSpringDamping: CGFloat = 0.45
        static let releaseSpringVelocity: CGFloat = 2
    }

    private(set) var viewModel: ButtonViewModel
    private let rootStack = UIStackView()
    private let centerStack = UIStackView()
    private let leftIconView = UIImageView()
    private let titleTextLabel = UILabel()
    private let rightIconView = UIImageView()

    init(viewModel: ButtonViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        setupContent()
        addTarget(self, action: #selector(handleTouchDown), for: .touchDown)
        addTarget(self, action: #selector(handleTouchDown), for: .touchDragEnter)
        addTarget(self, action: #selector(handleTouchUp), for: .touchUpInside)
        addTarget(self, action: #selector(handleTouchUp), for: .touchUpOutside)
        addTarget(self, action: #selector(handleTouchUp), for: .touchDragExit)
        addTarget(self, action: #selector(handleTouchUp), for: .touchCancel)
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        apply(viewModel)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(_ viewModel: ButtonViewModel) {
        self.viewModel = viewModel

        directionalLayoutMargins = viewModel.contentInsets
        backgroundColor = viewModel.backgroundColor
        layer.cornerRadius = viewModel.cornerRadius
        clipsToBounds = true
        isEnabled = viewModel.isEnabled
        alpha = viewModel.isEnabled ? 1 : 0.6

        titleTextLabel.text = viewModel.title
        titleTextLabel.font = viewModel.font
        titleTextLabel.textColor = Asset.Colors.textAndIconPrimaryInverted.color
    
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

        if !viewModel.isEnabled {
            transform = .identity
        }
    }

    @objc
    private func handleTouchDown() {
        guard viewModel.isEnabled else { return }

        UIView.animate(withDuration: Constants.pressAnimationDuration) {
            self.transform = CGAffineTransform(scaleX: Constants.pressedScale, y: Constants.pressedScale)
        }
    }

    @objc
    private func handleTouchUp() {
        guard viewModel.isEnabled else { return }

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
        viewModel.tapCommand.execute()
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

        centerStack.addArrangedSubview(leftIconView)
        centerStack.addArrangedSubview(titleTextLabel)
        centerStack.addArrangedSubview(rightIconView)

        rootStack.snp.makeConstraints { make in
            make.top.bottom.equalTo(layoutMarginsGuide)
            make.leading.greaterThanOrEqualTo(layoutMarginsGuide)
            make.trailing.lessThanOrEqualTo(layoutMarginsGuide)
            make.centerX.equalToSuperview()
        }
        
        rootStack.isUserInteractionEnabled = false
        titleTextLabel.isUserInteractionEnabled = false
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
    struct ButtonViewModel {
        let title: String
        let titleColor: UIColor
        let backgroundColor: UIColor
        let font: UIFont
        let cornerRadius: CGFloat
        let contentInsets: NSDirectionalEdgeInsets
        let height: CGFloat
        let isEnabled: Bool
        let tapCommand: Command
        let leftIcon: UIImage?
        let rightIcon: UIImage?
        let iconTintColor: UIColor?

        init(
            title: String,
            titleColor: UIColor,
            backgroundColor: UIColor,
            font: UIFont,
            cornerRadius: CGFloat,
            contentInsets: NSDirectionalEdgeInsets,
            height: CGFloat,
            isEnabled: Bool,
            tapCommand: Command,
            leftIcon: UIImage? = nil,
            rightIcon: UIImage? = nil,
            iconTintColor: UIColor? = nil
        ) {
            self.title = title
            self.titleColor = titleColor
            self.backgroundColor = backgroundColor
            self.font = font
            self.cornerRadius = cornerRadius
            self.contentInsets = contentInsets
            self.height = height
            self.isEnabled = isEnabled
            self.tapCommand = tapCommand
            self.leftIcon = leftIcon
            self.rightIcon = rightIcon
            self.iconTintColor = iconTintColor
        }
    }
}
