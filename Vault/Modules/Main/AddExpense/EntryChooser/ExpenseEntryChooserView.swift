import UIKit
import SnapKit

final class ExpenseEntryChooserView: UIView, LayoutScaleProviding, AddExpenseSheetContentSizing {
    private let headerView = AddExpenseSheetHeaderView()
    private let aiButton = Button()
    private let manualButton = Button()
    private let buttonStackView = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with viewModel: ExpenseEntryChooserViewModel) {
        headerView.apply(viewModel.header)
        aiButton.apply(viewModel.aiButton)
        manualButton.apply(viewModel.manualButton)
    }

    func fittingHeight(for width: CGFloat) -> CGFloat {
        layoutIfNeeded()

        return headerView.frame.maxY
        + spaceL
        + buttonStackView.frame.height
        + spaceS
        + safeAreaInsets.bottom
    }
}

private extension ExpenseEntryChooserView {
    func setupViews() {
        backgroundColor = Asset.Colors.backgroundPrimary.color

        buttonStackView.axis = .vertical
        buttonStackView.spacing = spaceS
    }

    func setupLayout() {
        addSubview(headerView)
        addSubview(buttonStackView)

        buttonStackView.addArrangedSubview(aiButton)
        buttonStackView.addArrangedSubview(manualButton)

        headerView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide)
            make.horizontalEdges.equalToSuperview()
        }

        buttonStackView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(spaceL)
            make.horizontalEdges.equalTo(safeAreaLayoutGuide).inset(spaceS)
            make.bottom.lessThanOrEqualTo(safeAreaLayoutGuide).inset(spaceS)
        }
    }
}
