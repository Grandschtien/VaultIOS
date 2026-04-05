import UIKit
import SnapKit

final class ExpenseCategoryFieldView: UIView, LayoutScaleProviding {
    private(set) var viewModel: ViewModel = .init()

    private let titleLabel = Label()
    private let cardButton = UIButton(type: .system)
    private let iconBackgroundView = UIView()
    private let iconLabel = Label()
    private let categoryLabel = Label()
    private let chevronImageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(_ viewModel: ViewModel) {
        self.viewModel = viewModel

        titleLabel.apply(viewModel.title)
        iconBackgroundView.backgroundColor = viewModel.iconBackgroundColor
        iconLabel.isHidden = !viewModel.isSelected
        categoryLabel.apply(viewModel.value)
        cardButton.isEnabled = viewModel.isEnabled
        cardButton.alpha = viewModel.isEnabled ? 1 : 0.65

        if let iconText = viewModel.iconText {
            iconLabel.apply(
                .init(
                    text: iconText,
                    font: Typography.typographyBold18,
                    textColor: Asset.Colors.textAndIconSecondary.color,
                    alignment: .center
                )
            )
        }

    }
}

private extension ExpenseCategoryFieldView {
    func setupViews() {
        backgroundColor = .clear

        cardButton.backgroundColor = Asset.Colors.interactiveInputBackground.color
        cardButton.layer.cornerRadius = sizeM
        cardButton.contentHorizontalAlignment = .fill
        cardButton.contentVerticalAlignment = .fill
        cardButton.addTarget(self, action: #selector(handleTap), for: .touchUpInside)

        iconBackgroundView.layer.cornerRadius = sizeS

        chevronImageView.image = UIImage(systemName: "chevron.right")
        chevronImageView.tintColor = Asset.Colors.textAndIconPlaceseholder.color
        chevronImageView.contentMode = .scaleAspectFit
    }

    func setupLayout() {
        addSubview(titleLabel)
        addSubview(cardButton)

        cardButton.addSubview(iconBackgroundView)
        iconBackgroundView.addSubview(iconLabel)
        cardButton.addSubview(categoryLabel)
        cardButton.addSubview(chevronImageView)

        titleLabel.snp.makeConstraints { make in
            make.top.horizontalEdges.equalToSuperview()
        }

        cardButton.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(spaceXS)
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalToSuperview()
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

        chevronImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(spaceS)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(sizeS)
        }

        categoryLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconBackgroundView.snp.trailing).offset(spaceS)
            make.trailing.lessThanOrEqualTo(chevronImageView.snp.leading).offset(-spaceS)
            make.centerY.equalToSuperview()
        }
    }

    @objc
    func handleTap() {
        viewModel.tapCommand.execute()
    }
}

extension ExpenseCategoryFieldView {
    struct ViewModel: Equatable {
        let title: Label.LabelViewModel
        let value: Label.LabelViewModel
        let iconText: String?
        let iconBackgroundColor: UIColor
        let isEnabled: Bool
        let tapCommand: Command

        init(
            title: Label.LabelViewModel = .init(),
            value: Label.LabelViewModel = .init(),
            iconText: String? = nil,
            iconBackgroundColor: UIColor = Asset.Colors.interactiveInputBackground.color,
            isEnabled: Bool = true,
            tapCommand: Command = .nope
        ) {
            self.title = title
            self.value = value
            self.iconText = iconText
            self.iconBackgroundColor = iconBackgroundColor
            self.isEnabled = isEnabled
            self.tapCommand = tapCommand
        }

        var isSelected: Bool {
            iconText != nil
        }
    }
}
