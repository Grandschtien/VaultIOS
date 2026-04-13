import UIKit
import SnapKit

final class ExpenseAIEntryView: UIView, LayoutScaleProviding {
    private let keyboardObserver = KeyboardObserver()
    private let scrollView = UIScrollView()
    private let contentView = UIView()
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
}

private extension ExpenseAIEntryView {
    func setupViews() {
        backgroundColor = Asset.Colors.backgroundPrimary.color
        keyboardObserver.attach(to: scrollView)

        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .interactive
        scrollView.alwaysBounceVertical = true
    }

    func setupLayout() {
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(headerView)
        contentView.addSubview(promptInputView)
        contentView.addSubview(processButton)

        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }

        headerView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.horizontalEdges.equalToSuperview()
        }

        promptInputView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(spaceS)
            make.horizontalEdges.equalToSuperview().inset(spaceS)
        }

        processButton.snp.makeConstraints { make in
            make.top.equalTo(promptInputView.snp.bottom).offset(spaceS)
            make.horizontalEdges.equalToSuperview().inset(spaceS)
            make.bottom.equalToSuperview().inset(spaceS)
        }
    }
}

extension ExpenseAIEntryView: AddExpenseSheetContentHeightProviding {
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

        let promptHeight = promptInputView.systemLayoutSizeFitting(
            CGSize(
                width: promptInputView.bounds.width > .zero ? promptInputView.bounds.width : width,
                height: UIView.layoutFittingCompressedSize.height
            ),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height

        let processButtonHeight = processButton.systemLayoutSizeFitting(
            CGSize(
                width: processButton.bounds.width > .zero ? processButton.bounds.width : width,
                height: UIView.layoutFittingCompressedSize.height
            ),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height

        return safeAreaInsets.top
            + headerHeight
            + spaceS
            + promptHeight
            + spaceS
            + processButtonHeight
            + safeAreaInsets.bottom
            + spaceS
    }
}
