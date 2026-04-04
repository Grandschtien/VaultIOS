import UIKit
import SnapKit
import SkeletonView

final class ExpenseCategoryPickerCell: UITableViewCell, LayoutScaleProviding, Reusable {
    private let cardView = UIView()
    private let iconBackgroundView = UIView()
    private let iconLabel = Label()
    private let titleLabel = Label()
    private let selectionImageView = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with viewModel: ExpenseCategoryPickerViewModel.RowViewModel) {
        if viewModel.isLoading {
            showSkeleton()
            return
        }

        hideSkeleton()

        iconBackgroundView.backgroundColor = viewModel.iconBackgroundColor
        iconLabel.apply(
            .init(
                text: viewModel.iconText,
                font: Typography.typographyBold18,
                textColor: Asset.Colors.textAndIconSecondary.color,
                alignment: .center
            )
        )
        titleLabel.apply(viewModel.title)
        selectionImageView.image = UIImage(
            systemName: viewModel.isSelected ? "checkmark.square.fill" : "square"
        )
        selectionImageView.tintColor = viewModel.isSelected
            ? Asset.Colors.interactiveElemetsPrimary.color
            : Asset.Colors.textAndIconPlaceseholder.color
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        hideSkeleton()
    }
}

private extension ExpenseCategoryPickerCell {
    func setupViews() {
        backgroundColor = .clear
        selectionStyle = .none

        cardView.backgroundColor = Asset.Colors.interactiveInputBackground.color
        cardView.layer.cornerRadius = sizeM
        cardView.isSkeletonable = true
        cardView.skeletonCornerRadius = Float(sizeM)

        iconBackgroundView.layer.cornerRadius = sizeS
        selectionImageView.contentMode = .scaleAspectFit
    }

    func setupLayout() {
        contentView.addSubview(cardView)
        cardView.addSubview(iconBackgroundView)
        iconBackgroundView.addSubview(iconLabel)
        cardView.addSubview(titleLabel)
        cardView.addSubview(selectionImageView)

        cardView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(spaceXXS)
            make.height.greaterThanOrEqualTo(sizeXL)
        }

        iconBackgroundView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(spaceS)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(sizeL)
        }

        iconLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        selectionImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(spaceS)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(sizeS)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconBackgroundView.snp.trailing).offset(spaceS)
            make.trailing.lessThanOrEqualTo(selectionImageView.snp.leading).offset(-spaceS)
            make.centerY.equalToSuperview()
        }
    }

    func showSkeleton() {
        iconBackgroundView.isHidden = true
        titleLabel.isHidden = true
        selectionImageView.isHidden = true
        cardView.showAnimatedGradientSkeleton()
    }

    func hideSkeleton() {
        iconBackgroundView.isHidden = false
        titleLabel.isHidden = false
        selectionImageView.isHidden = false
        cardView.hideSkeleton()
    }
}
