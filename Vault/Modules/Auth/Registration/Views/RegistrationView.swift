// Created by Egor Shkarin 16.03.2026

import UIKit
import SnapKit

final class RegistrationView: UIView, LayoutScaleProviding {
    private var viewModel: RegistrationViewModel = .init()
    private let keyboardObserver = KeyboardObserver()

    private let stepScrollView = UIScrollView()
    private let scrollContentView = UIView()
    private let buttonsStackView = UIStackView()

    private let stepLabel = Label()
    private let progressView = RegistrationProgressView()
    private let stepContentView = UIView()
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
            showScrollableStepView(accountStepView)
            accountStepView.configure(with: accountViewModel)

        case let .name(nameViewModel):
            showScrollableStepView(nameStepView)
            nameStepView.configure(with: nameViewModel)

        case let .currency(currencyViewModel):
            showCurrencyStepView()
            currencyStepView.configure(with: currencyViewModel)
        }
    }
}

private extension RegistrationView {
    func setupViews() {
        backgroundColor = Asset.Colors.backgroundPrimary.color
        keyboardObserver.attach(to: stepScrollView)

        stepScrollView.showsVerticalScrollIndicator = false
        stepScrollView.keyboardDismissMode = .interactive
        stepScrollView.alwaysBounceVertical = true
        buttonsStackView.axis = .vertical
        buttonsStackView.spacing = spaceS

        [accountStepView, nameStepView].forEach {
            stepContentView.addSubview($0)
            $0.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        stepLabel.setContentHuggingPriority(.required, for: .vertical)
    }

    func setupLayout() {
        [
            stepLabel,
            progressView,
            stepScrollView,
            currencyStepView,
            buttonsStackView
        ].forEach(addSubview)

        stepScrollView.addSubview(scrollContentView)
        scrollContentView.addSubview(stepContentView)

        buttonsStackView.addArrangedSubview(primaryButton)
        buttonsStackView.addArrangedSubview(secondaryButton)

        stepLabel.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide).offset(spaceM)
            make.leading.trailing.equalToSuperview().inset(spaceS)
        }

        progressView.snp.makeConstraints { make in
            make.top.equalTo(stepLabel.snp.bottom).offset(spaceXS)
            make.leading.trailing.equalToSuperview().inset(spaceS)
        }

        stepScrollView.snp.makeConstraints { make in
            make.top.equalTo(progressView.snp.bottom).offset(spaceM)
            make.leading.trailing.equalToSuperview().inset(spaceS)
            make.bottom.equalToSuperview()
        }

        scrollContentView.snp.makeConstraints { make in
            make.edges.equalTo(stepScrollView.contentLayoutGuide)
            make.width.equalTo(stepScrollView.frameLayoutGuide)
            make.height.greaterThanOrEqualTo(stepScrollView.frameLayoutGuide)
        }

        stepContentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        currencyStepView.snp.makeConstraints { make in
            make.top.equalTo(progressView.snp.bottom).offset(spaceM)
            make.leading.trailing.equalToSuperview().inset(spaceS)
            make.bottom.equalToSuperview()
        }

        buttonsStackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(spaceS)
            make.bottom.equalTo(safeAreaLayoutGuide)
        }

        bringSubviewToFront(buttonsStackView)
    }

    func showScrollableStepView(_ stepView: UIView) {
        stepScrollView.isHidden = false
        currencyStepView.isHidden = true

        accountStepView.isHidden = stepView !== accountStepView
        nameStepView.isHidden = stepView !== nameStepView
    }

    func showCurrencyStepView() {
        stepScrollView.isHidden = true
        currencyStepView.isHidden = false
        accountStepView.isHidden = true
        nameStepView.isHidden = true
    }
}
