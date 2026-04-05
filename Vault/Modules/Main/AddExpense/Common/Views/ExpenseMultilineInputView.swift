import UIKit
import SnapKit

final class ExpenseMultilineInputView: UIView, LayoutScaleProviding {
    private(set) var viewModel: ViewModel = .init()

    private let contentStackView = UIStackView()
    private let titleLabel = Label()
    private let containerView = UIView()
    private let textView = UITextView()
    private let placeholderLabel = Label()
    private let counterLabel = Label()

    private var minimumHeightConstraint: Constraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(_ viewModel: ViewModel) {
        self.viewModel = viewModel

        titleLabel.isHidden = viewModel.title == nil
        if let title = viewModel.title {
            titleLabel.apply(title)
        }

        if textView.text != viewModel.text {
            textView.text = viewModel.text
        }

        placeholderLabel.apply(
            .init(
                text: viewModel.placeholder,
                font: Typography.typographyRegular16,
                textColor: Asset.Colors.textAndIconPlaceseholder.color,
                alignment: .left,
                numberOfLines: 0,
                lineBreakMode: .byWordWrapping
            )
        )

        counterLabel.isHidden = viewModel.counter == nil
        if let counter = viewModel.counter {
            counterLabel.apply(counter)
        }

        textView.keyboardType = viewModel.keyboardType
        textView.autocapitalizationType = viewModel.autocapitalizationType
        textView.isEditable = viewModel.isEditable
        textView.isSelectable = viewModel.isEditable
        containerView.alpha = viewModel.isEditable ? 1 : 0.65
        minimumHeightConstraint?.update(offset: viewModel.minimumHeight == .zero ? sizeXXL : viewModel.minimumHeight)

        updatePlaceholderVisibility()
        updateTextInsets()
    }
}

private extension ExpenseMultilineInputView {
    func setupViews() {
        backgroundColor = .clear

        contentStackView.axis = .vertical
        contentStackView.spacing = spaceXS

        containerView.backgroundColor = Asset.Colors.interactiveInputBackground.color
        containerView.layer.cornerRadius = sizeM

        textView.backgroundColor = .clear
        textView.font = Typography.typographyRegular16
        textView.textColor = Asset.Colors.textAndIconPrimary.color
        textView.tintColor = Asset.Colors.interactiveElemetsPrimary.color
        textView.delegate = self

        placeholderLabel.isUserInteractionEnabled = false
        counterLabel.isUserInteractionEnabled = false
    }

    func setupLayout() {
        addSubview(contentStackView)
        contentStackView.addArrangedSubview(titleLabel)
        contentStackView.addArrangedSubview(containerView)

        containerView.addSubview(textView)
        containerView.addSubview(placeholderLabel)
        containerView.addSubview(counterLabel)

        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        containerView.snp.makeConstraints { make in
            minimumHeightConstraint = make.height.greaterThanOrEqualTo(sizeXXL).constraint
        }

        textView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        placeholderLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(spaceS)
            make.leading.equalToSuperview().offset(spaceS)
            make.trailing.equalToSuperview().inset(spaceS)
        }

        counterLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(spaceS)
            make.bottom.equalToSuperview().inset(spaceS)
        }
    }

    func updatePlaceholderVisibility() {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }

    func updateTextInsets() {
        textView.textContainerInset = UIEdgeInsets(
            top: spaceS,
            left: spaceS,
            bottom: viewModel.counter == nil ? spaceS : spaceXL,
            right: spaceS
        )
    }
}

extension ExpenseMultilineInputView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        updatePlaceholderVisibility()
        viewModel.onTextDidChange?.execute(textView.text)
    }
}

extension ExpenseMultilineInputView {
    struct ViewModel: Equatable {
        let title: Label.LabelViewModel?
        let text: String
        let placeholder: String
        let counter: Label.LabelViewModel?
        let minimumHeight: CGFloat
        let keyboardType: UIKeyboardType
        let autocapitalizationType: UITextAutocapitalizationType
        let isEditable: Bool
        let onTextDidChange: CommandOf<String>?

        init(
            title: Label.LabelViewModel? = nil,
            text: String = "",
            placeholder: String = "",
            counter: Label.LabelViewModel? = nil,
            minimumHeight: CGFloat = .zero,
            keyboardType: UIKeyboardType = .default,
            autocapitalizationType: UITextAutocapitalizationType = .sentences,
            isEditable: Bool = true,
            onTextDidChange: CommandOf<String>? = nil
        ) {
            self.title = title
            self.text = text
            self.placeholder = placeholder
            self.counter = counter
            self.minimumHeight = minimumHeight
            self.keyboardType = keyboardType
            self.autocapitalizationType = autocapitalizationType
            self.isEditable = isEditable
            self.onTextDidChange = onTextDidChange
        }
    }
}
