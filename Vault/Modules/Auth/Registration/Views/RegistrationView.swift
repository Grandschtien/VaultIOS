// Created by Egor Shkarin 16.03.2026

import UIKit
import SnapKit

final class RegistrationView: UIView, LayoutScaleProviding {
    private var viewModel: RegistrationViewModel = .init()

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let stepLabel = Label()
    private let progressView = RegistrationProgressView()

    private let stepContainerView = UIView()
    private let accountStepView = RegistrationAccountStepView()
    private let nameStepView = RegistrationNameStepView()
    private let currencyStepView = RegistrationCurrencyStepView()

    private let primaryButton = Button()
    private let secondaryButton = Button()

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

extension RegistrationView {
    func configure(with viewModel: RegistrationViewModel) {
        self.viewModel = viewModel

        stepLabel.apply(viewModel.stepLabel)
        progressView.apply(viewModel.progress)
        primaryButton.apply(viewModel.primaryButton)
        secondaryButton.apply(viewModel.secondaryButton)
        secondaryButton.isHidden = viewModel.isSecondaryButtonHidden

        switch viewModel.content {
        case let .account(accountViewModel):
            show(stepView: accountStepView)
            accountStepView.configure(with: accountViewModel)

        case let .name(nameViewModel):
            show(stepView: nameStepView)
            nameStepView.configure(with: nameViewModel)

        case let .currency(currencyViewModel):
            show(stepView: currencyStepView)
            currencyStepView.configure(with: currencyViewModel)
        }
    }
}

private extension RegistrationView {
    func setupViews() {
        backgroundColor = Asset.Colors.backgroundPrimary.color

        scrollView.showsVerticalScrollIndicator = false
        scrollView.isScrollEnabled = false

        [accountStepView, nameStepView, currencyStepView].forEach {
            stepContainerView.addSubview($0)
            $0.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        stepLabel.setContentHuggingPriority(.required, for: .vertical)
    }

    func setupLayout() {
        addSubview(contentView)

        [
            stepLabel,
            progressView,
            stepContainerView
        ].forEach {
            contentView.addSubview($0)
        }
        
        addSubview(primaryButton)
        addSubview(secondaryButton)
        contentView.snp.makeConstraints { make in
            make.top.trailing.leading.equalTo(safeAreaLayoutGuide)
            make.bottom.equalToSuperview()
        }

        stepLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(spaceM)
            make.leading.trailing.equalToSuperview().inset(spaceS)
        }

        progressView.snp.makeConstraints { make in
            make.top.equalTo(stepLabel.snp.bottom).offset(spaceXS)
            make.leading.trailing.equalToSuperview().inset(spaceS)
        }

        stepContainerView.snp.makeConstraints { make in
            make.top.equalTo(progressView.snp.bottom).offset(spaceM)
            make.leading.trailing.equalToSuperview().inset(spaceS)
            make.bottom.equalToSuperview()
        }

        primaryButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(spaceS)
        }

        secondaryButton.snp.makeConstraints { make in
            make.top.equalTo(primaryButton.snp.bottom).offset(spaceS)
            make.leading.trailing.equalToSuperview().inset(spaceS)
            make.bottom.equalToSuperview().inset(spaceL)
        }
    }

    func show(stepView: UIView) {
        accountStepView.isHidden = stepView !== accountStepView
        nameStepView.isHidden = stepView !== nameStepView
        currencyStepView.isHidden = stepView !== currencyStepView
    }
}
