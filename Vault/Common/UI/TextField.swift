//
//  TextField.swift
//  Vault
//
//  Created by Egor Shkarin on 10.03.2026.
//

import UIKit
import SnapKit

final class TextField: UIView, LayoutScaleProviding {
    private var viewModel: TextField.ViewModel = .init()

    private let contentStackView = UIStackView()
    private let topRowView = UIView()
    private let titleLabel = UILabel()
    private let additionalLabel = UILabel()
    private let inputContainerView = UIView()
    private let leftAccessoryContainer = UIView()
    private let rightAccessoryContainer = UIView()
    private let leftAccessoryImageView = UIImageView()
    private let rightAccessoryImageView = UIImageView()
    private let textField = UITextField()
    private let helpLabel = UILabel()

    private var leftAccessoryWidthConstraint: Constraint?
    private var leftAccessoryConstraint: Constraint?
    private var rightAccessoryWidthConstraint: Constraint?
    private var rightAccessorConstraint: Constraint?
    private var textFieldLeadingConstraint: Constraint?
    private var textFieldTrailingConstraint: Constraint?
    private var isSecureModeEnabled = false

    init() {
        super.init(frame: .zero)
        setupViews()
        setupConstraints()
        applyInternalStyle()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(_ viewModel: TextField.ViewModel) {
        self.viewModel = viewModel

        if textField.text != viewModel.text {
            textField.text = viewModel.text
        }

        titleLabel.text = viewModel.titleText
        additionalLabel.text = viewModel.additionalLabelText
        leftAccessoryImageView.image = viewModel.leftIcon?.withRenderingMode(.alwaysTemplate)
        helpLabel.text = viewModel.helpText
        helpLabel.textColor = viewModel.helpTextColor

        isSecureModeEnabled = viewModel.isSecureTextEntry
        setSecureTextEntry(viewModel.isSecureTextEntry)

        applyPlaceholder()
        updateTopRowVisibility()
        updateHelpVisibility()
        updateAdditionalLabelInteraction()
        updateAccessoryState()
    }
}

private extension TextField {
    func setupViews() {
        contentStackView.axis = .vertical
        contentStackView.spacing = 0

        addSubview(contentStackView)
        contentStackView.addArrangedSubview(topRowView)
        contentStackView.addArrangedSubview(inputContainerView)
        contentStackView.addArrangedSubview(helpLabel)

        topRowView.addSubview(titleLabel)
        topRowView.addSubview(additionalLabel)

        inputContainerView.addSubview(leftAccessoryContainer)
        inputContainerView.addSubview(textField)
        inputContainerView.addSubview(rightAccessoryContainer)

        leftAccessoryContainer.addSubview(leftAccessoryImageView)
        rightAccessoryContainer.addSubview(rightAccessoryImageView)

        contentStackView.setCustomSpacing(topToInputSpacing, after: topRowView)
        contentStackView.setCustomSpacing(inputToHelpSpacing, after: inputContainerView)

        additionalLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleAdditionalLabelTap)))
        rightAccessoryContainer.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleRightAccessoryTap)))

        textField.addTarget(self, action: #selector(handleTextChanged), for: .editingChanged)
        textField.addTarget(self, action: #selector(handlePrimaryActionTriggered), for: .primaryActionTriggered)
    }

    func setupConstraints() {
        contentStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        titleLabel.snp.makeConstraints {
            $0.top.bottom.leading.equalToSuperview()
            $0.trailing.lessThanOrEqualTo(additionalLabel.snp.leading).offset(-labelsSpacing)
        }

        additionalLabel.snp.makeConstraints {
            $0.top.bottom.trailing.equalToSuperview()
        }

        inputContainerView.snp.makeConstraints {
            $0.height.equalTo(inputHeight)
        }

        leftAccessoryContainer.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            leftAccessoryConstraint = $0.leading.equalToSuperview().constraint
            leftAccessoryWidthConstraint = $0.width.equalTo(accessoryContainerWidth).constraint
        }

        rightAccessoryContainer.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            rightAccessorConstraint = $0.trailing.equalToSuperview().constraint
            rightAccessoryWidthConstraint = $0.width.equalTo(accessoryContainerWidth).constraint
        }

        textField.snp.makeConstraints {
            textFieldLeadingConstraint = $0.leading.equalTo(leftAccessoryContainer.snp.trailing).offset(textHorizontalInset).constraint
            textFieldTrailingConstraint = $0.trailing.equalTo(rightAccessoryContainer.snp.leading).offset(-textHorizontalInset).constraint
            $0.top.bottom.equalToSuperview()
        }

        leftAccessoryImageView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(iconSize)
        }

        rightAccessoryImageView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(iconSize)
        }
    }

    func applyInternalStyle() {
        titleLabel.font = titleFont
        titleLabel.textColor = titleColor
        titleLabel.textAlignment = .left
        titleLabel.numberOfLines = 1

        additionalLabel.font = titleFont
        additionalLabel.textColor = additionalLabelColor
        additionalLabel.textAlignment = .right
        additionalLabel.numberOfLines = 1

        inputContainerView.backgroundColor = inputBackgroundColor
        inputContainerView.layer.cornerRadius = inputCornerRadius
        inputContainerView.layer.cornerCurve = .continuous

        leftAccessoryImageView.tintColor = iconTintColor
        leftAccessoryImageView.contentMode = .scaleAspectFit

        rightAccessoryImageView.tintColor = iconTintColor
        rightAccessoryImageView.contentMode = .scaleAspectFit

        textField.font = textFont
        textField.textColor = textColor
        textField.tintColor = cursorTintColor
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.returnKeyType = .done
        textField.clearButtonMode = .whileEditing

        helpLabel.font = helpFont
        helpLabel.numberOfLines = 0
    }

    func applyPlaceholder() {
        guard let placeholder = viewModel.placeholder, !placeholder.isEmpty else {
            textField.attributedPlaceholder = nil
            return
        }

        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .font: textFont,
                .foregroundColor: placeholderColor
            ]
        )
    }

    func updateTopRowVisibility() {
        topRowView.isHidden = !hasTopRowContent
    }

    func updateHelpVisibility() {
        helpLabel.isHidden = !hasContent(viewModel.helpText)
    }

    func updateAccessoryState() {
        let hasLeftIcon = viewModel.leftIcon != nil
        let hasRightIcon = resolvedRightIcon() != nil

        leftAccessoryContainer.isHidden = !hasLeftIcon
        rightAccessoryContainer.isHidden = !hasRightIcon
        rightAccessoryContainer.isUserInteractionEnabled = isSecureModeEnabled

        rightAccessoryImageView.image = resolvedRightIcon()?.withRenderingMode(.alwaysTemplate)

        leftAccessoryWidthConstraint?.update(offset: hasLeftIcon ? accessoryContainerWidth : 0)
        rightAccessoryWidthConstraint?.update(offset: hasRightIcon ? accessoryContainerWidth : 0)
        rightAccessorConstraint?.update(inset: hasRightIcon ? spaceS : 0)
        leftAccessoryConstraint?.update(offset: hasLeftIcon ? spaceS : 0)
        textFieldLeadingConstraint?.update(offset: hasLeftIcon ? iconToTextSpacing : textHorizontalInset)
        textFieldTrailingConstraint?.update(offset: hasRightIcon ? -iconToTextSpacing : -textHorizontalInset)
    }

    func updateAdditionalLabelInteraction() {
        additionalLabel.isUserInteractionEnabled = hasContent(viewModel.additionalLabelText) && viewModel.onAdditionalLabelTap != .nope
    }

    func resolvedRightIcon() -> UIImage? {
        if isSecureModeEnabled {
            return UIImage(systemName: textField.isSecureTextEntry ? "eye" : "eye.slash")
        }

        return viewModel.rightIcon
    }

    func setSecureTextEntry(_ isSecure: Bool) {
        guard textField.isSecureTextEntry != isSecure else {
            return
        }

        let selectedRange = textField.selectedTextRange
        textField.isSecureTextEntry = isSecure
        if let selectedRange {
            textField.selectedTextRange = selectedRange
        }
    }

    func hasContent(_ text: String?) -> Bool {
        guard let text else { return false }
        return !text.isEmpty
    }
}

// MARK: Actions
private extension TextField {
    @objc
    func handleTextChanged() {
        viewModel.onTextDidChanged?.execute(textField.text ?? "")
    }

    @objc
    func handlePrimaryActionTriggered() {
        viewModel.onReturn.execute()
    }

    @objc
    func handleAdditionalLabelTap() {
        guard additionalLabel.isUserInteractionEnabled else {
            return
        }

        viewModel.onAdditionalLabelTap.execute()
    }

    @objc
    func handleRightAccessoryTap() {
        guard isSecureModeEnabled else {
            return
        }

        setSecureTextEntry(!textField.isSecureTextEntry)
        updateAccessoryState()
    }
}

// MARK: Properties
private extension TextField {
    var hasTopRowContent: Bool {
        hasContent(viewModel.titleText) || hasContent(viewModel.additionalLabelText)
    }

    var inputHeight: CGFloat {
        spaceM + spaceS
    }

    var topToInputSpacing: CGFloat {
        spaceXS
    }

    var inputToHelpSpacing: CGFloat {
        spaceXXS
    }

    var labelsSpacing: CGFloat {
        spaceS
    }

    var textHorizontalInset: CGFloat {
        spaceS + spaceXXS
    }

    var iconSize: CGFloat {
        sizeS + spaceXXS
    }

    var iconHorizontalPadding: CGFloat {
        spaceXXS
    }

    var iconToTextSpacing: CGFloat {
        spaceXS
    }

    var accessoryContainerWidth: CGFloat {
        iconSize + iconHorizontalPadding * 2
    }

    var inputCornerRadius: CGFloat {
        inputHeight / 2
    }

    var titleFont: UIFont {
        Typography.typographySemibold14
    }

    var textFont: UIFont {
        Typography.typographyRegular16
    }

    var helpFont: UIFont {
        Typography.typographyRegular14
    }

    var titleColor: UIColor {
        Asset.Colors.textAndIconSecondary.color
    }

    var additionalLabelColor: UIColor {
        Asset.Colors.interactiveElemetsPrimary.color
    }

    var inputBackgroundColor: UIColor {
        Asset.Colors.interactiveInputBackground.color
    }

    var textColor: UIColor {
        Asset.Colors.textAndIconPrimary.color
    }

    var placeholderColor: UIColor {
        Asset.Colors.textAndIconPlaceseholder.color
    }

    var cursorTintColor: UIColor {
        Asset.Colors.interactiveElemetsPrimary.color
    }

    var iconTintColor: UIColor {
        Asset.Colors.textAndIconPlaceseholder.color
    }
}

// MARK: ViewModel
extension TextField {
    struct ViewModel: Equatable {
        let text: String?
        let placeholder: String?
        let isSecureTextEntry: Bool
        let titleText: String?
        let additionalLabelText: String?
        let leftIcon: UIImage?
        let rightIcon: UIImage?
        let helpText: String?
        let helpTextColor: UIColor
        let onTextDidChanged: CommandOf<String>?
        let onReturn: Command
        let onAdditionalLabelTap: Command

        init(
            text: String? = nil,
            placeholder: String? = nil,
            isSecureTextEntry: Bool = false,
            titleText: String? = nil,
            additionalLabelText: String? = nil,
            leftIcon: UIImage? = nil,
            rightIcon: UIImage? = nil,
            helpText: String? = nil,
            helpTextColor: UIColor = Asset.Colors.textAndIconSecondary.color,
            onTextDidChanged: CommandOf<String>? = nil,
            onReturn: Command = .nope,
            onAdditionalLabelTap: Command = .nope
        ) {
            self.text = text
            self.placeholder = placeholder
            self.isSecureTextEntry = isSecureTextEntry
            self.titleText = titleText
            self.additionalLabelText = additionalLabelText
            self.leftIcon = leftIcon
            self.rightIcon = rightIcon
            self.helpText = helpText
            self.helpTextColor = helpTextColor
            self.onTextDidChanged = onTextDidChanged
            self.onReturn = onReturn
            self.onAdditionalLabelTap = onAdditionalLabelTap
        }
    }
}
