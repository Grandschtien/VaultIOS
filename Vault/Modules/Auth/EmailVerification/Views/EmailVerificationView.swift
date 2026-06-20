import SnapKit
import UIKit

final class EmailVerificationView: UIView, LayoutScaleProviding {
    private var viewModel: EmailVerificationViewModel = .init()
    private let keyboardObserver = KeyboardObserver()

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let titleLabel = Label()
    private let subtitleLabel = Label()
    private let codeInputView = EmailVerificationCodeInputView()
    private let errorLabel = Label()
    private let resendPromptLabel = Label()
    private let resendActionStackView = UIStackView()
    private let resendButton = UIButton(type: .system)
    private let resendCountdownLabel = Label()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with viewModel: EmailVerificationViewModel) {
        let previousViewModel = self.viewModel
        self.viewModel = viewModel

        if previousViewModel.title != viewModel.title {
            titleLabel.apply(viewModel.title)
        }

        if previousViewModel.subtitle != viewModel.subtitle {
            subtitleLabel.apply(viewModel.subtitle)
        }

        if previousViewModel.codeInput != viewModel.codeInput {
            codeInputView.apply(viewModel.codeInput)
        }

        if previousViewModel.resendPrompt != viewModel.resendPrompt {
            resendPromptLabel.apply(viewModel.resendPrompt)
        }

        if let errorLabelViewModel = viewModel.errorLabel {
            errorLabel.isHidden = false
            if previousViewModel.errorLabel != viewModel.errorLabel {
                errorLabel.apply(errorLabelViewModel)
            }
        } else {
            errorLabel.isHidden = true
            errorLabel.text = nil
        }

        if previousViewModel.resendAction != viewModel.resendAction {
            updateResendAction(with: viewModel.resendAction)
        }
    }
}

private extension EmailVerificationView {
    func setupViews() {
        backgroundColor = Asset.Colors.backgroundPrimary.color
        keyboardObserver.attach(to: scrollView)

        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .interactive
        scrollView.alwaysBounceVertical = true

        errorLabel.isHidden = true

        resendButton.titleLabel?.font = Typography.typographyBold16
        resendButton.setTitleColor(Asset.Colors.interactiveElemetsPrimary.color, for: .normal)
        resendButton.setTitleColor(Asset.Colors.interactiveElemetsPrimary.color.withAlphaComponent(0.8), for: .disabled)
        resendButton.addTarget(self, action: #selector(handleTapResend), for: .touchUpInside)

        resendActionStackView.axis = .horizontal
        resendActionStackView.alignment = .center
        resendActionStackView.spacing = spaceXXS

        resendCountdownLabel.isHidden = true
    }

    func setupLayout() {
        addSubview(scrollView)
        scrollView.addSubview(contentView)

        [
            titleLabel,
            subtitleLabel,
            codeInputView,
            errorLabel,
            resendPromptLabel,
            resendActionStackView
        ].forEach {
            contentView.addSubview($0)
        }

        [
            resendButton,
            resendCountdownLabel
        ].forEach {
            resendActionStackView.addArrangedSubview($0)
        }

        scrollView.snp.makeConstraints {
            $0.edges.equalTo(safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints {
            $0.edges.equalTo(scrollView.contentLayoutGuide)
            $0.width.equalTo(scrollView.frameLayoutGuide)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide.snp.top).offset(spaceM)
            $0.leading.trailing.equalToSuperview().inset(spaceS)
        }

        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(spaceS)
            $0.leading.trailing.equalToSuperview().inset(spaceS)
        }

        codeInputView.snp.makeConstraints {
            $0.top.equalTo(subtitleLabel.snp.bottom).offset(spaceXL)
            $0.leading.trailing.equalToSuperview().inset(spaceS)
        }

        errorLabel.snp.makeConstraints {
            $0.top.equalTo(codeInputView.snp.bottom).offset(spaceS)
            $0.leading.trailing.equalToSuperview().inset(spaceS)
        }

        resendPromptLabel.snp.makeConstraints {
            $0.top.equalTo(errorLabel.snp.bottom).offset(spaceL)
            $0.leading.trailing.equalToSuperview().inset(spaceS)
        }

        resendActionStackView.snp.makeConstraints {
            $0.top.equalTo(resendPromptLabel.snp.bottom).offset(spaceXS)
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().inset(spaceXL)
        }
    }

    func updateResendAction(with viewModel: EmailVerificationViewModel.ResendActionViewModel) {
        resendButton.setTitle(viewModel.title, for: .normal)
        resendButton.isEnabled = viewModel.isEnabled
        resendButton.alpha = viewModel.isEnabled ? 1 : 0.8

        if let countdownLabelViewModel = viewModel.countdownLabel {
            resendCountdownLabel.isHidden = false
            resendCountdownLabel.apply(countdownLabelViewModel)
        } else {
            resendCountdownLabel.isHidden = true
            resendCountdownLabel.text = nil
        }
    }
}

private extension EmailVerificationView {
    @objc
    func handleTapResend() {
        guard viewModel.resendAction.isEnabled else {
            return
        }

        executeAfterDismissingKeyboard(viewModel.resendAction.tapCommand)
    }
}
