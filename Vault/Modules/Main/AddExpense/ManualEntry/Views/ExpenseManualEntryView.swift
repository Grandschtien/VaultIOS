import UIKit
import SnapKit

final class ExpenseManualEntryView: UIView, LayoutScaleProviding {
    private let headerView = AddExpenseSheetHeaderView()
    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()
    private let amountInputView = ExpenseAmountInputView()
    private let titleField = TextField()
    private let categoryFieldView = ExpenseCategoryFieldView()
    private let descriptionInputView = ExpenseMultilineInputView()
    private let confirmButton = Button()

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
        amountInputView.apply(viewModel.amountInput)
        titleField.apply(viewModel.titleField)
        categoryFieldView.apply(viewModel.categoryField)
        descriptionInputView.apply(viewModel.descriptionInput)
        confirmButton.apply(viewModel.confirmButton)
    }
}

private extension ExpenseManualEntryView {
    func setupViews() {
        backgroundColor = Asset.Colors.backgroundPrimary.color

        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .interactive

        contentStackView.axis = .vertical
        contentStackView.spacing = spaceS
    }

    func setupLayout() {
        addSubview(headerView)
        addSubview(scrollView)
        addSubview(confirmButton)

        scrollView.addSubview(contentStackView)
        contentStackView.addArrangedSubview(amountInputView)
        contentStackView.addArrangedSubview(titleField)
        contentStackView.addArrangedSubview(categoryFieldView)
        contentStackView.addArrangedSubview(descriptionInputView)

        headerView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide)
            make.horizontalEdges.equalToSuperview()
        }

        confirmButton.snp.makeConstraints { make in
            make.horizontalEdges.equalTo(safeAreaLayoutGuide).inset(spaceS)
            make.bottom.equalTo(safeAreaLayoutGuide).inset(spaceS)
        }

        scrollView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(spaceS)
            make.horizontalEdges.equalTo(safeAreaLayoutGuide).inset(spaceS)
            make.bottom.equalTo(confirmButton.snp.top).offset(-spaceS)
        }

        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }
    }
}
