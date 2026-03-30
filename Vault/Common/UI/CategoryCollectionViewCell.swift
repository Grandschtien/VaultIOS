// Created by Egor Shkarin 23.03.2026

import UIKit
import SnapKit
import SkeletonView

final class CategoryCollectionViewCell: UICollectionViewCell, LayoutScaleProviding, Reusable {
    private(set) var viewModel: ViewModel = .init()

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

    func configure(with viewModel: ViewModel) {
        self.viewModel = viewModel

        if viewModel.isLoading {
            showSkeleton()
            return
        }

        hideSkeleton()

        iconLabel.apply(
            .init(
                text: viewModel.iconText,
                font: Typography.typographyBold18,
                textColor: Asset.Colors.textAndIconSecondary.color,
                alignment: .center
            )
        )
        titleLabel.apply(viewModel.title)
        amountLabel.apply(viewModel.amount)
        amountLabel.isHidden = viewModel.isAmountHidden
        iconBackgroundView.backgroundColor = viewModel.iconBackgroundColor
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        hideSkeleton()
    }
}

private extension CategoryCollectionViewCell {
    func setupViews() {
        backgroundColor = .clear

        cardView.isSkeletonable = true

        cardView.backgroundColor = Asset.Colors.interactiveInputBackground.color
        cardView.layer.cornerRadius = sizeL
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.05
        cardView.layer.shadowOffset = CGSize(width: .zero, height: spaceXXS)
        cardView.layer.shadowRadius = spaceXS

        iconBackgroundView.layer.cornerRadius = sizeS
        cardView.skeletonCornerRadius = Float(sizeS)
    }

    func setupLayout() {
        contentView.addSubview(cardView)
        [iconBackgroundView, titleLabel, amountLabel].forEach { cardView.addSubview($0) }
        iconBackgroundView.addSubview(iconLabel)

        cardView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        iconBackgroundView.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().inset(spaceS)
            make.width.height.equalTo(sizeL)
        }

        iconLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(spaceS)
            make.trailing.equalToSuperview().inset(spaceS)
            make.top.equalTo(iconBackgroundView.snp.bottom).offset(spaceS)
        }

        amountLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(spaceS)
            make.trailing.equalToSuperview().inset(spaceS)
            make.top.equalTo(titleLabel.snp.bottom).offset(spaceXXS)
            make.bottom.lessThanOrEqualToSuperview().inset(spaceS)
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

extension CategoryCollectionViewCell {
    struct ViewModel: Equatable {
        let id: String
        let iconText: String
        let title: Label.LabelViewModel
        let amount: Label.LabelViewModel
        let isAmountHidden: Bool
        let iconBackgroundColor: UIColor
        let tapCommand: Command
        let isLoading: Bool

        init(
            id: String = "",
            iconText: String = "",
            title: Label.LabelViewModel = .init(),
            amount: Label.LabelViewModel = .init(),
            isAmountHidden: Bool = false,
            iconBackgroundColor: UIColor = Asset.Colors.interactiveInputBackground.color,
            tapCommand: Command = .nope,
            isLoading: Bool = false
        ) {
            self.id = id
            self.iconText = iconText
            self.title = title
            self.amount = amount
            self.isAmountHidden = isAmountHidden
            self.iconBackgroundColor = iconBackgroundColor
            self.tapCommand = tapCommand
            self.isLoading = isLoading
        }
    }
}
