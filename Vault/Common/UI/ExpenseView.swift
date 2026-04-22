// Created by Egor Shkarin 23.03.2026

import UIKit
import SnapKit

final class ExpenseView: UIView, LayoutScaleProviding {
    private(set) var viewModel: ViewModel = .init()

    private let cardView = UIView()
    private let iconBackgroundView = UIView()
    private let iconLabel = Label()
    private let titleLabel = Label()
    private let subtitleLabel = Label()
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

        iconLabel.apply(
            .init(
                text: viewModel.iconText,
                font: Typography.typographyBold18,
                textColor: Asset.Colors.textAndIconSecondary.color,
                alignment: .center
            )
        )
        titleLabel.apply(viewModel.title)
        subtitleLabel.apply(viewModel.subtitle)
        amountLabel.apply(viewModel.amount)

        iconBackgroundView.backgroundColor = viewModel.iconBackgroundColor
    }
}

private extension ExpenseView {
    func setupViews() {
        backgroundColor = .clear

        cardView.backgroundColor = Asset.Colors.interactiveInputBackground.color
        cardView.layer.cornerRadius = sizeL

        iconBackgroundView.layer.cornerRadius = sizeS
    }

    func setupLayout() {
        addSubview(cardView)

        [iconBackgroundView, titleLabel, subtitleLabel, amountLabel].forEach {
            cardView.addSubview($0)
        }
        amountLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        iconBackgroundView.addSubview(iconLabel)

        cardView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        iconBackgroundView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(spaceS)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(sizeL)
        }

        iconLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconBackgroundView.snp.trailing).offset(spaceS)
            make.top.equalToSuperview().offset(spaceS)
            make.trailing.lessThanOrEqualTo(amountLabel.snp.leading).offset(-spaceS)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(spaceXXXS)
            make.trailing.lessThanOrEqualTo(amountLabel.snp.leading).offset(-spaceS)
        }

        amountLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(spaceS)
            make.leading.greaterThanOrEqualTo(subtitleLabel.snp.trailing).offset(spaceXS)
        }
    }

}

extension ExpenseView {
    struct ViewModel: Equatable {
        let id: String
        let iconText: String
        let title: Label.LabelViewModel
        let subtitle: Label.LabelViewModel
        let amount: Label.LabelViewModel
        let iconBackgroundColor: UIColor
        let tapCommand: Command

        init(
            id: String = "",
            iconText: String = "",
            title: Label.LabelViewModel = .init(),
            subtitle: Label.LabelViewModel = .init(),
            amount: Label.LabelViewModel = .init(),
            iconBackgroundColor: UIColor = Asset.Colors.interactiveInputBackground.color,
            tapCommand: Command = .nope
        ) {
            self.id = id
            self.iconText = iconText
            self.title = title
            self.subtitle = subtitle
            self.amount = amount
            self.iconBackgroundColor = iconBackgroundColor
            self.tapCommand = tapCommand
        }
    }
}

extension ExpenseView: ConfigurableCellWrappedView {}
