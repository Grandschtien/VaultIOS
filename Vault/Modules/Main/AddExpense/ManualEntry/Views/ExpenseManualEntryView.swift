import UIKit
import SnapKit

final class ExpenseManualEntryView: UIView, LayoutScaleProviding {
    private let headerView = AddExpenseSheetHeaderView()
    private let contentStackView = UIStackView()
    private let amountInputView = ExpenseAmountInputView()
    private let titleField = TextField()
    private let categoryFieldView = ExpenseCategoryFieldView()
    private let descriptionInputView = ExpenseMultilineInputView()
    private let buttonsStackView = UIStackView()
    private let primaryButton = Button()
    private let skipButton = Button()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with viewModel: ExpenseManualEntryViewModel) {
        headerView.apply(viewModel.header)

        if let currentDraft = viewModel.currentDraft {
            amountInputView.apply(currentDraft.amountInput)
            titleField.apply(currentDraft.titleField)
            categoryFieldView.apply(currentDraft.categoryField)
            descriptionInputView.apply(currentDraft.descriptionInput)
        }

        primaryButton.apply(viewModel.primaryButton)

        skipButton.isHidden = viewModel.skipButton == nil
        if let skipButtonViewModel = viewModel.skipButton {
            skipButton.apply(skipButtonViewModel)
        }
    }
}

extension ExpenseManualEntryView: AddExpenseSheetContentHeightProviding {
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

        let contentHeight = contentStackView.systemLayoutSizeFitting(
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
            + contentHeight
            + safeAreaInsets.bottom
            + spaceS
    }
}

private extension ExpenseManualEntryView {
    func setupViews() {
        backgroundColor = Asset.Colors.backgroundPrimary.color

        contentStackView.axis = .vertical
        contentStackView.spacing = spaceS

        buttonsStackView.axis = .vertical
        buttonsStackView.spacing = spaceS
    }

    func setupLayout() {
        addSubview(headerView)
        addSubview(contentStackView)

        contentStackView.addArrangedSubview(amountInputView)
        contentStackView.addArrangedSubview(titleField)
        contentStackView.addArrangedSubview(categoryFieldView)
        contentStackView.addArrangedSubview(descriptionInputView)
        contentStackView.addArrangedSubview(buttonsStackView)

        buttonsStackView.addArrangedSubview(primaryButton)
        buttonsStackView.addArrangedSubview(skipButton)

        headerView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide)
            make.horizontalEdges.equalToSuperview()
        }

        contentStackView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(spaceS)
            make.horizontalEdges.equalTo(safeAreaLayoutGuide).inset(spaceS)
            make.bottom.equalTo(safeAreaLayoutGuide).inset(spaceS)
        }

        skipButton.isHidden = true
    }
}

extension ExpenseManualEntryView {
    struct DraftViewModel: Equatable {
        let amountInput: ExpenseAmountInputView.ViewModel
        let titleField: TextField.ViewModel
        let categoryField: ExpenseCategoryFieldView.ViewModel
        let descriptionInput: ExpenseMultilineInputView.ViewModel

        init(
            amountInput: ExpenseAmountInputView.ViewModel = .init(),
            titleField: TextField.ViewModel = .init(),
            categoryField: ExpenseCategoryFieldView.ViewModel = .init(),
            descriptionInput: ExpenseMultilineInputView.ViewModel = .init()
        ) {
            self.amountInput = amountInput
            self.titleField = titleField
            self.categoryField = categoryField
            self.descriptionInput = descriptionInput
        }
    }
}
