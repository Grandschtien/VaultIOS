//
//  Button.swift
//  Vault
//
//  Created by Егор Шкарин on 09.03.2026.
//

import UIKit

final class Button: UIButton {
    private(set) var viewModel: ButtonViewModel

    init(viewModel: ButtonViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
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

        var configuration = UIButton.Configuration.plain()
        configuration.title = viewModel.title
        configuration.baseForegroundColor = viewModel.titleColor
        configuration.contentInsets = viewModel.contentInsets
        self.configuration = configuration

        titleLabel?.font = viewModel.font
        self.backgroundColor = viewModel.backgroundColor
        layer.cornerRadius = viewModel.cornerRadius
        clipsToBounds = true
        isEnabled = viewModel.isEnabled

        if !viewModel.isEnabled {
            transform = .identity
        }
    }

    @objc
    private func handleTouchDown() {
        guard viewModel.isEnabled else { return }

        UIView.animate(withDuration: viewModel.pressAnimationDuration) {
            self.transform = CGAffineTransform(scaleX: self.viewModel.pressedScale, y: self.viewModel.pressedScale)
        }
    }

    @objc
    private func handleTouchUp() {
        guard viewModel.isEnabled else { return }

        UIView.animate(
            withDuration: viewModel.releaseAnimationDuration,
            delay: 0,
            usingSpringWithDamping: viewModel.releaseSpringDamping,
            initialSpringVelocity: viewModel.releaseSpringVelocity,
            options: [.allowUserInteraction, .beginFromCurrentState]
        ) {
            self.transform = .identity
        }
    }

    @objc
    private func handleTap() {
        viewModel.tapCommand.execute()
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
        let pressedScale: CGFloat
        let pressAnimationDuration: TimeInterval
        let releaseAnimationDuration: TimeInterval
        let releaseSpringDamping: CGFloat
        let releaseSpringVelocity: CGFloat

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
            pressedScale: CGFloat = 0.96,
            pressAnimationDuration: TimeInterval = 0.12,
            releaseAnimationDuration: TimeInterval = 0.38,
            releaseSpringDamping: CGFloat = 0.45,
            releaseSpringVelocity: CGFloat = 2
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
            self.pressedScale = pressedScale
            self.pressAnimationDuration = pressAnimationDuration
            self.releaseAnimationDuration = releaseAnimationDuration
            self.releaseSpringDamping = releaseSpringDamping
            self.releaseSpringVelocity = releaseSpringVelocity
        }
    }
}
