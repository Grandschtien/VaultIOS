//
//  Toast.swift
//  Vault
//
//  Created by Codex on 16.03.2026.
//

import UIKit
import SnapKit

enum ToastState: Equatable {
    case error
    case success
    case neutral
    case neuteral
}

final class Toast: UIView, LayoutScaleProviding {
    private enum Constants {
        static let horizontalInset: CGFloat = 16
        static let verticalInset: CGFloat = 12
        static let contentSpacing: CGFloat = 12
        static let iconSize: CGFloat = 20
    }

    private(set) var viewModel: ViewModel = .init()

    private let contentStack = UIStackView()
    private let iconImageView = UIImageView()
    private let titleLabel = Label()
    private let actionButton = UIButton(type: .system)
    private let tapGestureRecognizer = UITapGestureRecognizer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(_ viewModel: ViewModel) {
        self.viewModel = viewModel

        backgroundColor = viewModel.backgroundColor

        titleLabel.apply(viewModel.title)

        iconImageView.image = viewModel.icon.image
        iconImageView.tintColor = Asset.Colors.textAndIconPrimaryInverted.color
        iconImageView.isHidden = viewModel.icon == .none

        actionButton.setTitle(viewModel.buttonText, for: .normal)
        actionButton.setTitleColor(viewModel.buttonTextColor, for: .normal)
        actionButton.isHidden = !viewModel.isButtonVisible
    }
}

private extension Toast {
    @objc
    func handleActionButtonTap() {
        guard viewModel.isButtonVisible else {
            return
        }

        viewModel.command.execute()
    }

    @objc
    func handleToastTap() {
        viewModel.tapCommand.execute()
    }

    func setupView() {
        clipsToBounds = true
        layer.cornerRadius = spaceS

        contentStack.axis = .horizontal
        contentStack.alignment = .center
        contentStack.spacing = Constants.contentSpacing

        iconImageView.contentMode = .scaleAspectFit
        iconImageView.setContentHuggingPriority(.required, for: .horizontal)
        iconImageView.setContentCompressionResistancePriority(.required, for: .horizontal)

        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        actionButton.titleLabel?.font = Typography.typographySemibold14
        actionButton.setContentHuggingPriority(.required, for: .horizontal)
        actionButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        actionButton.addTarget(self, action: #selector(handleActionButtonTap), for: .touchUpInside)

        tapGestureRecognizer.addTarget(self, action: #selector(handleToastTap))
        tapGestureRecognizer.delegate = self
        tapGestureRecognizer.cancelsTouchesInView = false
        addGestureRecognizer(tapGestureRecognizer)
    }

    func setupLayout() {
        addSubview(contentStack)

        contentStack.addArrangedSubview(iconImageView)
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(actionButton)

        contentStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(
                UIEdgeInsets(
                    top: Constants.verticalInset,
                    left: Constants.horizontalInset,
                    bottom: Constants.verticalInset,
                    right: Constants.horizontalInset
                )
            )
        }

        iconImageView.snp.makeConstraints { make in
            make.size.equalTo(Constants.iconSize)
        }
    }
}

extension Toast {
    enum Icon: Equatable {
        case none
        case sfSymbol(name: String)

        var image: UIImage? {
            switch self {
            case .none:
                return nil
            case .sfSymbol(let name):
                return UIImage(systemName: name)
            }
        }
    }

    struct ViewModel: Equatable {
        let state: ToastState
        let title: Label.LabelViewModel
        let icon: Icon
        let backgroundColor: UIColor
        let buttonText: String?
        let buttonTextColor: UIColor
        let command: Command
        let tapCommand: Command

        var isButtonVisible: Bool {
            guard let buttonText else {
                return false
            }

            return !buttonText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && command != .nope
        }

        init(
            state: ToastState = .neutral,
            title: Label.LabelViewModel = .init(),
            icon: Icon = .none,
            backgroundColor: UIColor = .clear,
            buttonText: String? = nil,
            buttonTextColor: UIColor = Asset.Colors.interactiveElemetsPrimary.color,
            command: Command = .nope,
            tapCommand: Command = .nope
        ) {
            self.state = state
            self.title = title
            self.icon = icon
            self.backgroundColor = backgroundColor
            self.buttonText = buttonText
            self.buttonTextColor = buttonTextColor
            self.command = command
            self.tapCommand = tapCommand
        }
    }
}

extension Toast: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
    ) -> Bool {
        guard let touchedView = touch.view else {
            return true
        }

        return !touchedView.isDescendant(of: actionButton)
    }
}
