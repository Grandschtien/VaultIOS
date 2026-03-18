// Created by Egor Shkarin 18.03.2026

import UIKit
import SnapKit

final class RegistrationCurrencyCell: UITableViewCell, LayoutScaleProviding {
    static let reuseId = "RegistrationCurrencyCell"

    private let cardView = UIView()
    private let iconContainerView = UIView()
    private let iconLabel = Label()
    private let titleLabel = Label()
    private let subtitleLabel = Label()
    private let checkmarkImageView = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with viewModel: RegistrationViewModel.CurrencyRowViewModel) {
        titleLabel.apply(viewModel.title)
        subtitleLabel.apply(viewModel.subtitle)

        iconLabel.apply(
            .init(
                text: String(viewModel.subtitle.text.prefix(1)),
                font: Typography.typographyBold18,
                textColor: Asset.Colors.textAndIconSecondary.color,
                alignment: .center
            )
        )

        if viewModel.isSelected {
            cardView.layer.borderWidth = 2
            cardView.layer.borderColor = Asset.Colors.interactiveElemetsPrimary.color.cgColor
            checkmarkImageView.image = UIImage(systemName: "checkmark.circle.fill")
            checkmarkImageView.tintColor = Asset.Colors.interactiveElemetsPrimary.color
        } else {
            cardView.layer.borderWidth = 0
            cardView.layer.borderColor = UIColor.clear.cgColor
            checkmarkImageView.image = UIImage(systemName: "circle")
            checkmarkImageView.tintColor = Asset.Colors.textAndIconPlaceseholder.color.withAlphaComponent(0.6)
        }
    }
}

private extension RegistrationCurrencyCell {
    func setupViews() {
        selectionStyle = .none
        backgroundColor = .clear

        cardView.backgroundColor = Asset.Colors.interactiveInputBackground.color
        cardView.layer.cornerRadius = 20

        iconContainerView.backgroundColor = Asset.Colors.backgroundPrimary.color
        iconContainerView.layer.cornerRadius = 16

        checkmarkImageView.contentMode = .scaleAspectFit
    }

    func setupLayout() {
        contentView.addSubview(cardView)

        [iconContainerView, titleLabel, subtitleLabel, checkmarkImageView].forEach {
            cardView.addSubview($0)
        }
        iconContainerView.addSubview(iconLabel)

        cardView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(spaceXXS)
            make.leading.trailing.equalToSuperview()
        }

        iconContainerView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(spaceS)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(32)
        }

        iconLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(spaceS)
            make.leading.equalTo(iconContainerView.snp.trailing).offset(spaceS)
            make.trailing.lessThanOrEqualTo(checkmarkImageView.snp.leading).offset(-spaceS)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(spaceXXS)
            make.leading.equalTo(titleLabel)
            make.trailing.lessThanOrEqualTo(checkmarkImageView.snp.leading).offset(-spaceS)
        }

        checkmarkImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(spaceS)
            make.width.height.equalTo(20)
        }
    }
}
