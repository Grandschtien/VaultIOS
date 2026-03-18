// Created by Egor Shkarin 18.03.2026

import UIKit
import SnapKit

final class RegistrationAccountStepView: UIView, LayoutScaleProviding {
    private let titleLabel = Label()
    private let subtitleLabel = Label()

    private let stackView = UIStackView()
    private let emailField = TextField()
    private let passwordField = TextField()
    private let confirmPasswordField = TextField()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with viewModel: RegistrationViewModel.AccountViewModel) {
        titleLabel.apply(viewModel.title)
        subtitleLabel.apply(viewModel.subtitle)
        emailField.apply(viewModel.emailField)
        passwordField.apply(viewModel.passwordField)
        confirmPasswordField.apply(viewModel.confirmPasswordField)
    }
}

private extension RegistrationAccountStepView {
    func setupViews() {
        stackView.axis = .vertical
        stackView.spacing = spaceS
    }

    func setupLayout() {
        [titleLabel, subtitleLabel, stackView].forEach {
            $0.setContentHuggingPriority(.required, for: .vertical)
            addSubview($0)
        }

        [emailField, passwordField, confirmPasswordField].forEach {
            $0.setContentHuggingPriority(.required, for: .vertical)
            stackView.addArrangedSubview($0)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(spaceS)
            make.leading.trailing.equalToSuperview()
        }

        stackView.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(spaceL)
            make.leading.trailing.equalToSuperview()
        }
    }
}
