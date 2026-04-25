import UIKit
import SnapKit

final class ForgotPasswordView: UIView, LayoutScaleProviding, ImageProviding {
    private let keyboardObserver = KeyboardObserver()
    private var closeCommand: Command = .nope

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let headerView = UIView()
    private let contentStackView = UIStackView()
    private let closeButton = UIButton(type: .system)
    private let titleLabel = Label()
    private let emailField = TextField()
    private let sendButton = Button()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with viewModel: ForgotPasswordViewModel) {
        closeCommand = viewModel.closeButton.tapCommand
        closeButton.isEnabled = viewModel.closeButton.isEnabled
        closeButton.alpha = viewModel.closeButton.isEnabled ? 1 : 0.4
        titleLabel.apply(viewModel.title)
        emailField.apply(viewModel.emailField)
        sendButton.apply(viewModel.sendButton)
    }
}

extension ForgotPasswordView: AddExpenseSheetContentHeightProviding {
    func preferredContentHeight(for width: CGFloat) -> CGFloat {
        layoutIfNeeded()

        let headerHeight = headerView.systemLayoutSizeFitting(
            CGSize(
                width: headerView.bounds.width > .zero ? headerView.bounds.width : width,
                height: UIView.layoutFittingCompressedSize.height
            ),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height

        let stackHeight = contentStackView.systemLayoutSizeFitting(
            CGSize(
                width: contentStackView.bounds.width > .zero ? contentStackView.bounds.width : width,
                height: UIView.layoutFittingCompressedSize.height
            ),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height

        return safeAreaInsets.top
            + headerHeight
            + spaceS
            + stackHeight
            + spaceL
    }
}

private extension ForgotPasswordView {
    func setupViews() {
        backgroundColor = Asset.Colors.backgroundPrimary.color
        keyboardObserver.attach(to: scrollView)

        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .interactive
        scrollView.alwaysBounceVertical = true

        contentStackView.axis = .vertical
        contentStackView.spacing = spaceL

        closeButton.tintColor = Asset.Colors.textAndIconPrimary.color
        closeButton.setImage(xmarkImage, for: .normal)
        closeButton.addTarget(self, action: #selector(handleTapClose), for: .touchUpInside)
    }

    func setupLayout() {
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(headerView)
        contentView.addSubview(contentStackView)
        headerView.addSubview(titleLabel)
        headerView.addSubview(closeButton)
        [emailField, sendButton].forEach(contentStackView.addArrangedSubview)

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }

        headerView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.horizontalEdges.equalToSuperview()
        }

        closeButton.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(spaceS)
            make.bottom.lessThanOrEqualToSuperview().inset(spaceS)
            make.size.equalTo(sizeM)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(spaceS)
            make.trailing.lessThanOrEqualTo(closeButton.snp.leading).offset(-spaceS)
            make.bottom.equalToSuperview().inset(spaceS)
        }

        contentStackView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(spaceS)
            make.horizontalEdges.equalToSuperview().inset(spaceS)
            make.bottom.equalToSuperview().inset(spaceL)
        }
    }

    @objc
    func handleTapClose() {
        executeAfterDismissingKeyboard(closeCommand)
    }
}
