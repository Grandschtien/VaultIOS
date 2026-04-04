import UIKit
import SnapKit

final class ExpenseAmountInputView: UIView, LayoutScaleProviding {
    private(set) var viewModel: ViewModel = .init()

    private let titleLabel = Label()
    private let textField = UITextField()

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
    }
}

private extension ExpenseAmountInputView {
    func setupViews() {
        backgroundColor = .clear

        textField.font = Typography.typographyBold36
        textField.textColor = Asset.Colors.textAndIconPrimary.color
        textField.tintColor = Asset.Colors.interactiveElemetsPrimary.color
        textField.textAlignment = .center
        textField.keyboardType = .decimalPad
        textField.delegate = self
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
        return separatorsCount <= 1
    }
}

extension ExpenseAmountInputView {
    struct ViewModel: Equatable {
        let title: Label.LabelViewModel
        let text: String
        let placeholder: String
        let onTextDidChange: CommandOf<String>?

        init(
            title: Label.LabelViewModel = .init(),
            text: String = "",
            placeholder: String = "",
            onTextDidChange: CommandOf<String>? = nil
        ) {
            self.title = title
            self.text = text
            self.placeholder = placeholder
            self.onTextDidChange = onTextDidChange
        }
    }
}
