// Created by Egor Shkarin 18.03.2026

import UIKit
import SnapKit

final class RegistrationNameStepView: UIView, LayoutScaleProviding {
    private let titleLabel = Label()
    private let subtitleLabel = Label()
    private let nameField = TextField()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with viewModel: RegistrationViewModel.NameViewModel) {
        titleLabel.apply(viewModel.title)
        subtitleLabel.apply(viewModel.subtitle)
        nameField.apply(viewModel.nameField)
    }
}

private extension RegistrationNameStepView {
    func setupLayout() {
        [titleLabel, subtitleLabel, nameField].forEach {
            addSubview($0)
            $0.setContentHuggingPriority(.required, for: .vertical)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(spaceS)
            make.leading.trailing.equalToSuperview()
        }

        nameField.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(spaceL)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
}
