// Created by Egor Shkarin 23.03.2026

import UIKit
import SnapKit
import SkeletonView

final class MainSummarySectionView: UIView, LayoutScaleProviding {
    private let cardView = UIView()
    private let titleLabel = Label()
    private let amountLabel = Label()
    private let trendContainerView = UIView()
    private let trendLabel = Label()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with viewModel: ViewModel) {
        if viewModel.isLoading {
            showSkeleton()
            return
        }

        hideSkeleton()

        titleLabel.apply(viewModel.title)
        amountLabel.apply(viewModel.amount)
        trendLabel.apply(viewModel.trend)

        trendContainerView.isHidden = viewModel.trend.text.isEmpty
    }
}

private extension MainSummarySectionView {
    func setupViews() {
        backgroundColor = .clear

        cardView.isSkeletonable = true

        cardView.backgroundColor = Asset.Colors.interactiveElemetsPrimary.color
        cardView.layer.cornerRadius = sizeM
        cardView.layer.shadowColor = Asset.Colors.interactiveElemetsPrimary.color.cgColor
        cardView.layer.shadowOpacity = 0.2
        cardView.layer.shadowOffset = CGSize(width: .zero, height: spaceXS)
        cardView.layer.shadowRadius = sizeS

        trendContainerView.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        trendContainerView.layer.cornerRadius = sizeS + spaceXXS
    }

    func setupLayout() {
        addSubview(cardView)
        [titleLabel, amountLabel, trendContainerView].forEach { cardView.addSubview($0) }
        trendContainerView.addSubview(trendLabel)

        cardView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(sizeXL * 2 + sizeM)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(spaceS)
            make.leading.trailing.equalToSuperview().inset(spaceS)
        }

        amountLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(spaceS)
            make.top.equalTo(titleLabel.snp.bottom).offset(spaceXXS)
        }

        trendContainerView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(spaceS)
            make.top.equalTo(amountLabel.snp.bottom).offset(spaceS)
            make.height.equalTo(sizeM + spaceXXS)
            make.bottom.lessThanOrEqualToSuperview().inset(spaceS)
        }

        trendLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(spaceS - spaceXXS)
            make.centerY.equalToSuperview()
        }
    }

    func showSkeleton() {
        titleLabel.isHidden = true
        amountLabel.isHidden = true
        trendContainerView.isHidden = true
        trendLabel.isHidden = true

        cardView.showAnimatedGradientSkeleton()
    }

    func hideSkeleton() {
        titleLabel.isHidden = false
        amountLabel.isHidden = false
        trendContainerView.isHidden = false
        trendLabel.isHidden = false

        cardView.hideSkeleton()
    }
}

extension MainSummarySectionView {
    struct ViewModel: Equatable {
        let title: Label.LabelViewModel
        let amount: Label.LabelViewModel
        let trend: Label.LabelViewModel
        let isLoading: Bool

        init(
            title: Label.LabelViewModel = .init(),
            amount: Label.LabelViewModel = .init(),
            trend: Label.LabelViewModel = .init(),
            isLoading: Bool = false
        ) {
            self.title = title
            self.amount = amount
            self.trend = trend
            self.isLoading = isLoading
        }
    }
}
