import UIKit
import SnapKit

final class AnalyticsCategorySummaryCell: UITableViewCell, LayoutScaleProviding, ImageProviding, Reusable {
    private let cardView = UIView()
    private let iconBackgroundView = UIView()
    private let iconLabel = Label()
    private let titleLabel = Label()
    private let amountLabel = Label()
    private let shareLabel = Label()
    private let chevronImageView = UIImageView()
    private let progressTrackView = UIView()
    private let progressFillView = UIView()
    private var isInteractive = true

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with viewModel: ViewModel) {
        isInteractive = viewModel.isInteractive
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
        shareLabel.apply(viewModel.share)
        iconBackgroundView.backgroundColor = viewModel.iconBackgroundColor
        progressFillView.backgroundColor = viewModel.progressColor
        selectionStyle = .none
        chevronImageView.isHidden = viewModel.isInteractive == false
        progressFillView.snp.remakeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(min(max(viewModel.progress, .zero), 1))
        }
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)

        guard isInteractive else {
            cardView.alpha = 1
            return
        }

        let updates = {
            self.cardView.alpha = highlighted ? 0.75 : 1
        }

        if animated {
            UIView.animate(withDuration: 0.2, animations: updates)
        } else {
            updates()
        }
    }
}

private extension AnalyticsCategorySummaryCell {
    func setupViews() {
        backgroundColor = .clear

        cardView.backgroundColor = Asset.Colors.interactiveInputBackground.color
        cardView.layer.cornerRadius = sizeM

        iconBackgroundView.layer.cornerRadius = sizeS

        progressTrackView.backgroundColor = Asset.Colors.backgroundPrimary.color
        progressTrackView.layer.cornerRadius = spaceXXS
        progressTrackView.clipsToBounds = true

        progressFillView.layer.cornerRadius = spaceXXS

        chevronImageView.image = chevronRightImage
        chevronImageView.tintColor = Asset.Colors.textAndIconPlaceseholder.color
        chevronImageView.contentMode = .scaleAspectFit
    }

    func setupLayout() {
        contentView.addSubview(cardView)
        [
            iconBackgroundView,
            titleLabel,
            amountLabel,
            shareLabel,
            chevronImageView,
            progressTrackView
        ].forEach { cardView.addSubview($0) }
        iconBackgroundView.addSubview(iconLabel)
        progressTrackView.addSubview(progressFillView)

        cardView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(spaceXS)
            make.horizontalEdges.equalToSuperview()
        }

        iconBackgroundView.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().inset(spaceS)
            make.width.height.equalTo(sizeL)
        }

        iconLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconBackgroundView.snp.trailing).offset(spaceS)
            make.trailing.lessThanOrEqualTo(amountLabel.snp.leading).offset(-spaceS)
            make.top.equalTo(iconBackgroundView)
        }

        chevronImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(spaceS)
            make.width.height.equalTo(sizeXS)
        }

        amountLabel.snp.makeConstraints { make in
            make.top.equalTo(iconBackgroundView)
            make.trailing.equalTo(chevronImageView.snp.leading).offset(-spaceS)
        }

        shareLabel.snp.makeConstraints { make in
            make.top.equalTo(amountLabel.snp.bottom).offset(spaceXXS)
            make.trailing.equalTo(chevronImageView.snp.leading).offset(-spaceS)
        }

        progressTrackView.snp.makeConstraints { make in
            make.top.equalTo(iconBackgroundView.snp.bottom).offset(spaceS)
            make.leading.equalTo(titleLabel)
            make.trailing.equalToSuperview().inset(spaceS)
            make.bottom.equalToSuperview().inset(spaceS)
            make.height.equalTo(spaceXS)
        }

        progressFillView.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0)
        }
    }
}

extension AnalyticsCategorySummaryCell {
    struct ViewModel: Equatable {
        let id: String
        let iconText: String
        let iconBackgroundColor: UIColor
        let progressColor: UIColor
        let progress: Double
        let title: Label.LabelViewModel
        let amount: Label.LabelViewModel
        let share: Label.LabelViewModel
        let tapCommand: Command
        let isInteractive: Bool

        init(
            id: String = "",
            iconText: String = "",
            iconBackgroundColor: UIColor = Asset.Colors.interactiveInputBackground.color,
            progressColor: UIColor = Asset.Colors.interactiveElemetsPrimary.color,
            progress: Double = .zero,
            title: Label.LabelViewModel = .init(),
            amount: Label.LabelViewModel = .init(),
            share: Label.LabelViewModel = .init(),
            tapCommand: Command = .nope,
            isInteractive: Bool = true
        ) {
            self.id = id
            self.iconText = iconText
            self.iconBackgroundColor = iconBackgroundColor
            self.progressColor = progressColor
            self.progress = progress
            self.title = title
            self.amount = amount
            self.share = share
            self.tapCommand = tapCommand
            self.isInteractive = isInteractive
        }
    }
}
