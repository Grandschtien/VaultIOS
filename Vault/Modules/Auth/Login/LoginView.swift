// Created by Egor Shkarin 14.03.2026

import UIKit
import SnapKit

final class LoginView: UIView, LayoutScaleProviding {
    private var viewModel: LoginViewModel = .init()
    private let keyboardObserver = KeyboardObserver()

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let logoImageView = UIImageView()
    private let titleLabel = Label()
    private let subtitleLabel = Label()

    private let formStackView = UIStackView()
    private let emailTextField = TextField()
    private let passwordTextField = TextField()
    private let signInButton = Button()

    private let footerStackView = UIStackView()
    private let privacyLabel = Label()
    private let termsLabel = Label()
    private let supportLabel = Label()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension LoginView {
    func configure(with viewModel: LoginViewModel) {
        self.viewModel = viewModel

        logoImageView.image = viewModel.logo
        titleLabel.apply(viewModel.title)
        subtitleLabel.apply(viewModel.subtitle)
        emailTextField.apply(viewModel.emailField)
        passwordTextField.apply(viewModel.passwordField)
        signInButton.apply(viewModel.signInButton)

        privacyLabel.apply(viewModel.privacyLabel)
        termsLabel.apply(viewModel.termsLabel)
        supportLabel.apply(viewModel.supportLabel)
    }
}

private extension LoginView {
    func setupViews() {
        backgroundColor = Asset.Colors.backgroundPrimary.color
        keyboardObserver.attach(to: scrollView)

        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .interactive
        scrollView.alwaysBounceVertical = true

        logoImageView.contentMode = .scaleAspectFit

        formStackView.axis = .vertical
        formStackView.spacing = spaceS

        footerStackView.axis = .horizontal
        footerStackView.spacing = spaceS
        footerStackView.alignment = .center
        footerStackView.distribution = .fillProportionally

        [privacyLabel, termsLabel, supportLabel].forEach {
            footerStackView.addArrangedSubview($0)
            $0.setContentCompressionResistancePriority(.required, for: .horizontal)
        }
    }

    func setupLayout() {
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        [
            logoImageView,
            titleLabel,
            subtitleLabel,
            formStackView,
            signInButton,
            footerStackView
        ].forEach {
            contentView.addSubview($0)
        }

        formStackView.addArrangedSubview(emailTextField)
        formStackView.addArrangedSubview(passwordTextField)

        scrollView.snp.makeConstraints {
            $0.edges.equalTo(safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints {
            $0.edges.equalTo(scrollView.contentLayoutGuide)
            $0.width.equalTo(scrollView.frameLayoutGuide)
        }

        logoImageView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(spaceL)
            $0.centerX.equalToSuperview()
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(logoImageView.snp.bottom)
            $0.centerX.equalToSuperview()
        }

        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(spaceM)
            $0.centerX.equalToSuperview()
        }

        formStackView.snp.makeConstraints {
            $0.top.equalTo(subtitleLabel.snp.bottom).offset(spaceL)
            $0.leading.trailing.equalToSuperview().inset(spaceS)
        }

        signInButton.snp.makeConstraints {
            $0.top.equalTo(formStackView.snp.bottom).offset(spaceM)
            $0.leading.trailing.equalToSuperview().inset(spaceS)
        }

        footerStackView.snp.makeConstraints {
            $0.top.equalTo(signInButton.snp.bottom).offset(spaceL)
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().inset(spaceL)
        }
    }
}
