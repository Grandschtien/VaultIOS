import SnapKit
import UIKit

final class EmailVerificationCodeInputView: UIView, LayoutScaleProviding {
    struct ViewModel: Equatable {
        let code: String
        let isErrorState: Bool
        let isEnabled: Bool
        let onCodeDidChange: CommandOf<String>

        init(
            code: String = "",
            isErrorState: Bool = false,
            isEnabled: Bool = true,
            onCodeDidChange: CommandOf<String> = .init(action: nil)
        ) {
            self.code = code
            self.isErrorState = isErrorState
            self.isEnabled = isEnabled
            self.onCodeDidChange = onCodeDidChange
        }
    }

    private enum Constants {
        static let digitsCount = 6
    }

    private var viewModel: ViewModel = .init()
    private var didApplyInitialFocus = false

    private let stackView = UIStackView()
    private let hiddenTextField = UITextField()
    private var digitViews: [UIView] = []
    private var digitLabels: [UILabel] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()

        guard window != nil, !didApplyInitialFocus, viewModel.isEnabled else {
            return
        }

        didApplyInitialFocus = true
        hiddenTextField.becomeFirstResponder()
    }

    func apply(_ viewModel: ViewModel) {
        self.viewModel = viewModel

        if hiddenTextField.text != viewModel.code {
            hiddenTextField.text = viewModel.code
        }

        hiddenTextField.isEnabled = viewModel.isEnabled
        isUserInteractionEnabled = viewModel.isEnabled
        alpha = viewModel.isEnabled ? 1 : 0.7

        applyCode(viewModel.code)
        updateBorderState(isErrorState: viewModel.isErrorState)
    }
}

private extension EmailVerificationCodeInputView {
    func setupViews() {
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = spaceXS

        hiddenTextField.keyboardType = .numberPad
        hiddenTextField.textContentType = .oneTimeCode
        hiddenTextField.textColor = .clear
        hiddenTextField.tintColor = .clear
        hiddenTextField.addTarget(self, action: #selector(handleEditingChanged), for: .editingChanged)
        hiddenTextField.delegate = self

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGestureRecognizer)

        for _ in 0..<Constants.digitsCount {
            let digitView = UIView()
            let label = UILabel()

            digitView.backgroundColor = Asset.Colors.backgroundPrimary.color
            digitView.layer.cornerRadius = sizeS
            digitView.layer.cornerCurve = .continuous
            digitView.layer.borderWidth = 2

            label.font = Typography.typographyBold26
            label.textColor = Asset.Colors.textAndIconPrimary.color
            label.textAlignment = .center

            digitViews.append(digitView)
            digitLabels.append(label)

            digitView.addSubview(label)
            stackView.addArrangedSubview(digitView)

            label.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(spaceXS)
            }

            digitView.snp.makeConstraints { make in
                make.height.equalTo(sizeXL)
            }
        }
    }

    func setupLayout() {
        addSubview(hiddenTextField)
        addSubview(stackView)

        hiddenTextField.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func applyCode(_ code: String) {
        let digits = Array(code.prefix(Constants.digitsCount)).map(String.init)

        for (index, label) in digitLabels.enumerated() {
            label.text = digits.indices.contains(index) ? digits[index] : ""
        }
    }

    func updateBorderState(isErrorState: Bool) {
        let borderColor = isErrorState
            ? Asset.Colors.errorColor.color.cgColor
            : Asset.Colors.interactiveElemetsPrimary.color.cgColor

        digitViews.forEach {
            $0.layer.borderColor = borderColor
        }
    }

    func sanitizedCode(from currentText: String, range: NSRange, replacement: String) -> String {
        let digitsReplacement = replacement.filter(\.isNumber)
        guard let swiftRange = Range(range, in: currentText) else {
            return String(currentText.filter(\.isNumber).prefix(Constants.digitsCount))
        }

        let updated = currentText.replacingCharacters(in: swiftRange, with: digitsReplacement)
        return String(updated.filter(\.isNumber).prefix(Constants.digitsCount))
    }
}

private extension EmailVerificationCodeInputView {
    @objc
    func handleTap() {
        guard viewModel.isEnabled else {
            return
        }

        hiddenTextField.becomeFirstResponder()
    }

    @objc
    func handleEditingChanged() {
        let value = String((hiddenTextField.text ?? "").filter(\.isNumber).prefix(Constants.digitsCount))

        if hiddenTextField.text != value {
            hiddenTextField.text = value
        }

        applyCode(value)
        viewModel.onCodeDidChange.execute(value)
    }
}

extension EmailVerificationCodeInputView: UITextFieldDelegate {
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        let currentText = textField.text ?? ""
        let updatedValue = sanitizedCode(
            from: currentText,
            range: range,
            replacement: string
        )

        textField.text = updatedValue
        applyCode(updatedValue)
        viewModel.onCodeDidChange.execute(updatedValue)
        return false
    }
}
