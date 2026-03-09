//
//  ViewController.swift
//  Vault
//
//  Created by Егор Шкарин on 01.02.2026.
//

import UIKit

final class ViewController: UIViewController {
    private let viewModel = ElementsScreenViewModel()

    private lazy var titleLabel = Label(viewModel: viewModel.titleLabel)
    private lazy var subtitleLabel = Label(viewModel: viewModel.subtitleLabel)
    private lazy var primaryButton = Button(viewModel: viewModel.primaryButton)
    private lazy var secondaryButton = Button(viewModel: viewModel.secondaryButton)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupLayout()
    }

    private func setupView() {
        view.backgroundColor = UIColor(named: "background_primary")

        [titleLabel, subtitleLabel, primaryButton, secondaryButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
    }

    private func setupLayout() {
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 48),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            primaryButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 32),
            primaryButton.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            primaryButton.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            primaryButton.heightAnchor.constraint(equalToConstant: viewModel.primaryButton.height),

            secondaryButton.topAnchor.constraint(equalTo: primaryButton.bottomAnchor, constant: 12),
            secondaryButton.leadingAnchor.constraint(equalTo: primaryButton.leadingAnchor),
            secondaryButton.trailingAnchor.constraint(equalTo: primaryButton.trailingAnchor),
            secondaryButton.heightAnchor.constraint(equalToConstant: viewModel.secondaryButton.height)
        ])
    }
}

struct ElementsScreenViewModel {
    let titleLabel: Label.LabelViewModel
    let subtitleLabel: Label.LabelViewModel

    let primaryButton: Button.ButtonViewModel
    let secondaryButton: Button.ButtonViewModel

    init() {
        titleLabel = Label.LabelViewModel(
            text: "Vault",
            font: Typography.typographyBold36,
            textColor: UIColor(named: "text_and_icon_primary") ?? .label,
            alignment: .left,
            numberOfLines: 1,
            lineBreakMode: .byTruncatingTail
        )

        subtitleLabel = Label.LabelViewModel(
            text: "Secure notes and personal data",
            font: Typography.typographyRegular16,
            textColor: UIColor(named: "text_and_icon_secondary") ?? .secondaryLabel,
            alignment: .left,
            numberOfLines: 0,
            lineBreakMode: .byWordWrapping
        )

        primaryButton = Button.ButtonViewModel(
            title: "Continue",
            titleColor: UIColor(named: "text_and_icon_primary") ?? .white,
            backgroundColor: UIColor(named: "interactive_elemets_primary") ?? .systemBlue,
            font: Typography.typographySemibold16,
            cornerRadius: 16,
            contentInsets: NSDirectionalEdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16),
            height: 52,
            isEnabled: true,
            tapCommand: .make {
                print("Primary button tapped")
            },
            pressedScale: 0.95,
            pressAnimationDuration: 0.1,
            releaseAnimationDuration: 0.34,
            releaseSpringDamping: 0.42,
            releaseSpringVelocity: 2.2
        )

        secondaryButton = Button.ButtonViewModel(
            title: "Skip",
            titleColor: UIColor(named: "text_and_icon_primary") ?? .label,
            backgroundColor: UIColor(named: "interactive_input_background") ?? .clear,
            font: Typography.typographySemibold16,
            cornerRadius: 16,
            contentInsets: NSDirectionalEdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16),
            height: 52,
            isEnabled: true,
            tapCommand: .make {
                print("Secondary button tapped")
            },
            pressedScale: 0.96,
            pressAnimationDuration: 0.1,
            releaseAnimationDuration: 0.34,
            releaseSpringDamping: 0.45,
            releaseSpringVelocity: 2
        )
    }
}
