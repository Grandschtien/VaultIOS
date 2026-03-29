// Created by Egor Shkarin on 28.03.2026

import UIKit
import SnapKit
import SkeletonView

final class CategorySummaryView: UIView, LayoutScaleProviding {
    private let cardView = UIView()
    private let iconBackgroundView = UIView()
    private let iconLabel = Label()
    private let titleLabel = Label()
    private let amountLabel = Label()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with viewModel: CategoryViewModel.SummaryViewModel) {
        if viewModel.isLoading {
            showSkeleton()
            return
        }

        hideSkeleton()

        iconLabel.apply(
            .init(
                text: viewModel.iconText,
                font: Typography.typographyBold18,
                textColor: Asset.Colors.textAndIconPrimaryInverted.color,
                alignment: .center
            )
        )
        cardView.backgroundColor = viewModel.cardBackgroundColor
        cardView.layer.borderColor = viewModel.cardBorderColor.cgColor
        titleLabel.apply(viewModel.title)
        amountLabel.apply(viewModel.amount)
        iconBackgroundView.backgroundColor = viewModel.iconBackgroundColor
    }
}

private extension CategorySummaryView {
    func setupViews() {
        backgroundColor = .clear

        cardView.backgroundColor = Asset.Colors.interactiveInputBackground.color
        cardView.layer.cornerRadius = sizeM
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = Asset.Colors.interactiveInputBackground.color.cgColor
        cardView.isSkeletonable = true
        cardView.skeletonCornerRadius = Float(sizeM)
        iconBackgroundView.layer.cornerRadius = sizeS
    }

    func setupLayout() {
        addSubview(cardView)
        [iconBackgroundView, titleLabel, amountLabel].forEach {
            cardView.addSubview($0)
        }
        iconBackgroundView.addSubview(iconLabel)

        cardView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        iconBackgroundView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(spaceS)
            make.top.equalToSuperview().offset(spaceS)
            make.width.height.equalTo(sizeL)
        }

        iconLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconBackgroundView.snp.trailing).offset(spaceXS)
            make.trailing.equalToSuperview().inset(spaceS)
            make.top.equalToSuperview().offset(spaceS)
        }

        amountLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.trailing.equalToSuperview().inset(spaceS)
            make.top.equalTo(titleLabel.snp.bottom).offset(spaceXXS)
            make.bottom.equalToSuperview().inset(spaceS)
        }
    }

    func showSkeleton() {
        iconLabel.isHidden = true
        titleLabel.isHidden = true
        amountLabel.isHidden = true

        cardView.showAnimatedGradientSkeleton()
    }

    func hideSkeleton() {
        iconLabel.isHidden = false
        titleLabel.isHidden = false
        amountLabel.isHidden = false

        cardView.hideSkeleton()
    }
}
