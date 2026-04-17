import UIKit
import SnapKit

final class ExpenseAmountInputView: UIView, LayoutScaleProviding {
    private(set) var viewModel: ViewModel = .init()

    private let titleLabel = Label()
    private let currencyContainerView = UIView()
    private let currencyLabel = Label()
    private let textField = CenteredPrefixTextField()

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
        titleLabel.apply(viewModel.title)
        currencyLabel.apply(viewModel.currencyLabel)

        if textField.text != viewModel.text {
            textField.text = viewModel.text
        }

        textField.attributedPlaceholder = NSAttributedString(
            string: viewModel.placeholder,
            attributes: [
                .font: Typography.typographyBold36,
                .foregroundColor: Asset.Colors.textAndIconPlaceseholder.color
            ]
        )
        textField.isEnabled = viewModel.isEnabled
        textField.alpha = viewModel.isEnabled ? 1 : 0.65
        currencyContainerView.alpha = viewModel.isEnabled ? 1 : 0.65
        textField.leftViewMode = viewModel.currencyLabel.text.isEmpty ? .never : .always
        updateCurrencyAccessoryLayout()
        textField.setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateCurrencyAccessoryLayout()
    }
}

private extension ExpenseAmountInputView {
    func setupViews() {
        backgroundColor = .clear

        textField.font = Typography.typographyBold36
        textField.textColor = Asset.Colors.textAndIconPrimary.color
        textField.tintColor = Asset.Colors.interactiveElemetsPrimary.color
        textField.textAlignment = .left
        textField.keyboardType = .decimalPad
        textField.delegate = self
        textField.leftView = currencyContainerView
        textField.leftViewMode = .always
        textField.addTarget(self, action: #selector(handleTextChanged), for: .editingChanged)
    }

    func setupLayout() {
        addSubview(titleLabel)
        addSubview(textField)

        titleLabel.snp.makeConstraints { make in
            make.top.horizontalEdges.equalToSuperview()
        }

        textField.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(spaceXS)
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }

    @objc
    func handleTextChanged() {
        viewModel.onTextDidChange?.execute(textField.text ?? "")
    }

    func updateCurrencyAccessoryLayout() {
        let currencyText = viewModel.currencyLabel.text
        guard !currencyText.isEmpty else {
            currencyContainerView.frame = .zero
            textField.prefixWidth = .zero
            return
        }

        currencyLabel.sizeToFit()

        let labelSize = currencyLabel.bounds.size
        let containerWidth = labelSize.width + spaceXS
        let containerHeight = max(textField.bounds.height, labelSize.height)

        currencyContainerView.frame = CGRect(
            x: .zero,
            y: .zero,
            width: containerWidth,
            height: containerHeight
        )
        textField.prefixWidth = containerWidth
        currencyLabel.frame = CGRect(
            x: .zero,
            y: (containerHeight - labelSize.height) / 2,
            width: labelSize.width,
            height: labelSize.height
        )

        if currencyLabel.superview !== currencyContainerView {
            currencyContainerView.addSubview(currencyLabel)
        }
    }
}

private final class CenteredPrefixTextField: UITextField {
    var prefixWidth: CGFloat = .zero

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        adjustedTextRect(forBounds: bounds)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        adjustedTextRect(forBounds: bounds)
    }

    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        adjustedTextRect(forBounds: bounds)
    }

    override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        guard let leftView, prefixWidth > .zero else {
            return super.leftViewRect(forBounds: bounds)
        }

        let groupWidth = contentWidth() + prefixWidth
        let originX = max(.zero, (bounds.width - groupWidth) / 2)

        return CGRect(
            x: originX,
            y: (bounds.height - leftView.bounds.height) / 2,
            width: prefixWidth,
            height: leftView.bounds.height
        )
    }
}

private extension CenteredPrefixTextField {
    func adjustedTextRect(forBounds bounds: CGRect) -> CGRect {
        guard prefixWidth > .zero else {
            return bounds
        }

        let groupWidth = contentWidth() + prefixWidth
        let originX = max(.zero, (bounds.width - groupWidth) / 2) + prefixWidth

        return CGRect(
            x: originX,
            y: .zero,
            width: max(.zero, bounds.width - originX),
            height: bounds.height
        )
    }

    func contentWidth() -> CGFloat {
        let displayedText: String
        if let text, !text.isEmpty {
            displayedText = text
        } else if let placeholder {
            displayedText = placeholder
        } else if let attributedPlaceholder = attributedPlaceholder?.string {
            displayedText = attributedPlaceholder
        } else {
            displayedText = ""
        }

        guard !displayedText.isEmpty else {
            return .zero
        }

        let textFont = font ?? Typography.typographyBold36
        return ceil((displayedText as NSString).size(withAttributes: [.font: textFont]).width)
    }
}

extension ExpenseAmountInputView: UITextFieldDelegate {
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        ExpenseAmountInputFilter.shouldChange(
            currentText: textField.text ?? "",
            range: range,
            replacementString: string
        )
    }
}

enum ExpenseAmountInputFilter {
    private static let decimalSeparators = CharacterSet(charactersIn: ".,")
    private static let allowedCharacters = CharacterSet.decimalDigits.union(decimalSeparators)

    static func shouldChange(
        currentText: String,
        range: NSRange,
        replacementString: String
    ) -> Bool {
        if replacementString.isEmpty {
            return true
        }

        guard let textRange = Range(range, in: currentText) else {
            return false
        }

        let updatedText = currentText.replacingCharacters(in: textRange, with: replacementString)
        let unicodeScalars = updatedText.unicodeScalars

        guard unicodeScalars.allSatisfy({ allowedCharacters.contains($0) }) else {
            return false
        }

        let separatorsCount = unicodeScalars.filter { decimalSeparators.contains($0) }.count
        guard separatorsCount <= 1 else {
            return false
        }

        guard let separatorIndex = updatedText.firstIndex(where: {
            $0 == "." || $0 == ","
        }) else {
            return true
        }

        let fractionalDigitsCount = updatedText.distance(
            from: updatedText.index(after: separatorIndex),
            to: updatedText.endIndex
        )

        return fractionalDigitsCount <= 2
    }
}

extension ExpenseAmountInputView {
    struct ViewModel: Equatable {
        let title: Label.LabelViewModel
        let currencyLabel: Label.LabelViewModel
        let text: String
        let placeholder: String
        let isEnabled: Bool
        let onTextDidChange: CommandOf<String>?

        init(
            title: Label.LabelViewModel = .init(),
            currencyLabel: Label.LabelViewModel = .init(),
            text: String = "",
            placeholder: String = "",
            isEnabled: Bool = true,
            onTextDidChange: CommandOf<String>? = nil
        ) {
            self.title = title
            self.currencyLabel = currencyLabel
            self.text = text
            self.placeholder = placeholder
            self.isEnabled = isEnabled
            self.onTextDidChange = onTextDidChange
        }
    }
}
