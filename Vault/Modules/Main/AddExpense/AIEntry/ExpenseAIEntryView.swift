import UIKit
import SnapKit

final class ExpenseAIEntryView: UIView, LayoutScaleProviding, AddExpenseSheetContentSizing {
    private let headerView = AddExpenseSheetHeaderView()
    private let promptInputView = ExpenseMultilineInputView()
    private let processButton = Button()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with viewModel: ExpenseAIEntryViewModel) {
        headerView.apply(viewModel.header)
        promptInputView.apply(viewModel.promptInput)
        processButton.apply(viewModel.processButton)
    }

    func fittingHeight(for width: CGFloat) -> CGFloat {
        layoutIfNeeded()

        return headerView.frame.maxY
        + spaceS
        + promptInputView.frame.height
        + spaceS
        + processButton.frame.height
        + spaceS
        + safeAreaInsets.bottom
    }
}

private extension ExpenseAIEntryView {
    func setupViews() {
        backgroundColor = Asset.Colors.backgroundPrimary.color
    }

    func setupLayout() {
        addSubview(headerView)
        addSubview(promptInputView)
        addSubview(processButton)

        headerView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide)
            make.horizontalEdges.equalToSuperview()
        }

        promptInputView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(spaceS)
            make.horizontalEdges.equalTo(safeAreaLayoutGuide).inset(spaceS)
        }

        processButton.snp.makeConstraints { make in
            make.horizontalEdges.equalTo(safeAreaLayoutGuide).inset(spaceS)
            make.bottom.equalTo(safeAreaLayoutGuide).inset(spaceS)
        }
    }
}
