import UIKit
import SnapKit

final class CategoryEmojiPickerCell: UITableViewCell, LayoutScaleProviding, Reusable {
    private let emojiLabel = Label()
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

    func configure(with viewModel: CategoryEmojiPickerViewModel.RowViewModel) {
        emojiLabel.apply(
            .init(
                text: viewModel.emoji,
                font: Typography.typographyBold20,
                textColor: Asset.Colors.textAndIconPrimary.color,
                alignment: .left
            )
        )
        checkmarkImageView.isHidden = !viewModel.isSelected
    }
}

private extension CategoryEmojiPickerCell {
    func setupViews() {
        backgroundColor = .clear
        selectionStyle = .none

        checkmarkImageView.image = UIImage(systemName: "checkmark")
        checkmarkImageView.tintColor = Asset.Colors.interactiveElemetsPrimary.color
    }

    func setupLayout() {
        contentView.addSubview(emojiLabel)
        contentView.addSubview(checkmarkImageView)

        emojiLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(spaceS)
            make.top.bottom.equalToSuperview().inset(spaceS)
        }

        checkmarkImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(spaceS)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(sizeS)
        }
    }
}
