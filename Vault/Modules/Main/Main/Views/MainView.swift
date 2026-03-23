// Created by Egor Shkarin 23.03.2026

import UIKit
import SnapKit

final class MainView: UIView, LayoutScaleProviding {
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()

    private let summarySectionView = MainSummarySectionView()
    private let categoriesSectionView = MainCategoriesSectionView()
    private let expensesSectionView = MainExpensesSectionView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension MainView {
    func configure(with viewModel: MainViewModel) {
        summarySectionView.configure(with: viewModel.summarySection)
        categoriesSectionView.configure(with: viewModel.categoriesSection)
        expensesSectionView.configure(with: viewModel.expensesSection)
    }
}

private extension MainView {
    func setupViews() {
        backgroundColor = Asset.Colors.backgroundPrimary.color

        scrollView.showsVerticalScrollIndicator = false

        stackView.axis = .vertical
        stackView.spacing = spaceM
    }

    func setupLayout() {
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)

        [summarySectionView, categoriesSectionView, expensesSectionView].forEach {
            stackView.addArrangedSubview($0)
        }

        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView.snp.width)
        }

        stackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(spaceS)
            make.leading.trailing.equalToSuperview().inset(spaceS)
            make.bottom.equalToSuperview().inset(spaceS)
        }
    }
}
