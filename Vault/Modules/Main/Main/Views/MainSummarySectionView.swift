// Created by Egor Shkarin 23.03.2026

import UIKit
import SnapKit
import SkeletonView

final class MainSummarySectionView: UIView, LayoutScaleProviding {
    private let cardView = UIView()
    private let errorView = FullScreenCommonErrorView()
    private let titleLabel = Label()
    private let periodDescriptionLabel = Label()
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
            cardView.isHidden = false
            errorView.isHidden = true
            showSkeleton()
            return
        } else {
            cardView.backgroundColor = Asset.Colors.interactiveElemetsPrimary.color
            cardView.layer.shadowColor = Asset.Colors.interactiveElemetsPrimary.color.cgColor
            hideSkeleton()
        }

        if let errorViewModel = viewModel.errorViewModel {
            cardView.isHidden = true
            errorView.isHidden = false
            errorView.apply(errorViewModel)
            return
        }

        cardView.isHidden = false
        errorView.isHidden = true

        titleLabel.apply(viewModel.title)
        periodDescriptionLabel.apply(viewModel.periodDescription)
        amountLabel.apply(viewModel.amount)
        
        if let trend = viewModel.trend {
            trendLabel.apply(trend)
        }
    
        trendContainerView.isHidden = viewModel.trend == nil
    }
}

private extension MainSummarySectionView {
    func setupViews() {
        backgroundColor = .clear

        cardView.isSkeletonable = true
        errorView.isHidden = true

        trendContainerView.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        trendContainerView.layer.cornerRadius = sizeS
        cardView.skeletonCornerRadius = Float(sizeM)
        cardView.layer.cornerRadius = sizeM
        cardView.layer.shadowOpacity = 0.2
        cardView.layer.shadowOffset = CGSize(width: .zero, height: spaceXS)
        cardView.layer.shadowRadius = sizeS
    }

    func setupLayout() {
        addSubview(cardView)
        addSubview(errorView)
        [titleLabel, periodDescriptionLabel, amountLabel].forEach { cardView.addSubview($0) }

        cardView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        errorView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(spaceS)
            make.leading.trailing.equalToSuperview().inset(spaceS)
        }

        amountLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(spaceS)
            make.top.equalTo(titleLabel.snp.bottom).offset(spaceXXS)
        }

        periodDescriptionLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(spaceS)
            make.top.equalTo(amountLabel.snp.bottom).offset(spaceXXS)
            make.bottom.equalToSuperview().inset(spaceS)
        }
    }

    func showSkeleton() {
        titleLabel.isHidden = true
        periodDescriptionLabel.isHidden = true
        amountLabel.isHidden = true
        trendContainerView.isHidden = true
        trendLabel.isHidden = true

        cardView.showAnimatedGradientSkeleton()
    }

    func hideSkeleton() {
        titleLabel.isHidden = false
        periodDescriptionLabel.isHidden = false
        amountLabel.isHidden = false
        trendContainerView.isHidden = false
        trendLabel.isHidden = false

        cardView.hideSkeleton()
    }
}

extension MainSummarySectionView {
    struct ViewModel: Equatable {
        let title: Label.LabelViewModel
        let periodDescription: Label.LabelViewModel
        let amount: Label.LabelViewModel
        let trend: Label.LabelViewModel?
        let isLoading: Bool
        let errorViewModel: FullScreenCommonErrorView.ViewModel?

        init(
            title: Label.LabelViewModel = .init(),
            periodDescription: Label.LabelViewModel = .init(),
            amount: Label.LabelViewModel = .init(),
            trend: Label.LabelViewModel? = .init(),
            isLoading: Bool = false,
            errorViewModel: FullScreenCommonErrorView.ViewModel? = nil
        ) {
            self.title = title
            self.periodDescription = periodDescription
            self.amount = amount
            self.trend = trend
            self.isLoading = isLoading
            self.errorViewModel = errorViewModel
        }
    }
}
