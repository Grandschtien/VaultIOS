import UIKit
import SnapKit
import SkeletonView

final class ProfileGeneralSectionView: UIView, LayoutScaleProviding {
    private let titleLabel = Label()
    private let cardView = UIView()
    private let currencyRowView = ProfileGeneralRowView()
    private let languageRowView = ProfileGeneralRowView()
    private let separatorView = UIView()

    private var isSkeletonAnimating = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(
        title: Label.LabelViewModel,
        rows: [ProfileViewModel.GeneralRow]
    ) {
        titleLabel.apply(title)
        currencyRowView.configure(with: rows.first ?? .init())
        languageRowView.configure(with: rows.dropFirst().first ?? .init())
    }

    func setLoading(_ isLoading: Bool) {
        if isLoading {
            showSkeleton()
        } else {
            hideSkeleton()
        }
    }
}

private extension ProfileGeneralSectionView {
    func setupViews() {
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = sizeL
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = Asset.Colors.textAndIconPlaceseholder.color.withAlphaComponent(0.15).cgColor
        cardView.clipsToBounds = true
        cardView.isSkeletonable = true
        cardView.skeletonCornerRadius = Float(sizeL)

        separatorView.backgroundColor = Asset.Colors.textAndIconPlaceseholder.color.withAlphaComponent(0.15)
    }

    func setupLayout() {
        addSubview(titleLabel)
        addSubview(cardView)

        cardView.addSubview(currencyRowView)
        cardView.addSubview(separatorView)
        cardView.addSubview(languageRowView)

        titleLabel.snp.makeConstraints {
            $0.top.horizontalEdges.equalToSuperview()
            $0.height.greaterThanOrEqualTo(sizeS)
        }

        cardView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(spaceS)
            $0.horizontalEdges.bottom.equalToSuperview()
            $0.height.greaterThanOrEqualTo(sizeXXL)
        }

        currencyRowView.snp.makeConstraints {
            $0.top.horizontalEdges.equalToSuperview()
            $0.height.equalTo(sizeXL)
        }

        separatorView.snp.makeConstraints {
            $0.top.equalTo(currencyRowView.snp.bottom)
            $0.leading.trailing.equalToSuperview().inset(spaceS)
            $0.height.equalTo(1)
        }

        languageRowView.snp.makeConstraints {
            $0.top.equalTo(separatorView.snp.bottom)
            $0.bottom.horizontalEdges.equalToSuperview()
            $0.height.equalTo(sizeXL)
        }
    }

    func showSkeleton() {
        guard !isSkeletonAnimating else {
            return
        }

        isSkeletonAnimating = true
        currencyRowView.setContentHidden(true)
        languageRowView.setContentHidden(true)
        cardView.showAnimatedGradientSkeleton()
    }

    func hideSkeleton() {
        guard isSkeletonAnimating else {
            return
        }

        isSkeletonAnimating = false
        currencyRowView.setContentHidden(false)
        languageRowView.setContentHidden(false)
        cardView.hideSkeleton()
    }
}

private final class ProfileGeneralRowView: UIControl, LayoutScaleProviding {
    private let iconBackgroundView = UIView()
    private let iconView = UIImageView()
    private let titleLabel = Label()
    private let subtitleLabel = Label()
    private var tapCommand: Command = .nope

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with viewModel: ProfileViewModel.GeneralRow) {
        iconBackgroundView.backgroundColor = viewModel.iconBackgroundColor
        iconView.image = viewModel.icon
        titleLabel.apply(viewModel.title)
        subtitleLabel.apply(viewModel.subtitle)
        tapCommand = viewModel.tapCommand
        isUserInteractionEnabled = viewModel.tapCommand != .nope
    }

    func setContentHidden(_ isHidden: Bool) {
        iconBackgroundView.isHidden = isHidden
        titleLabel.isHidden = isHidden
        subtitleLabel.isHidden = isHidden
    }
}

private extension ProfileGeneralRowView {
    func setupViews() {
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)

        [iconView].forEach {
            $0.contentMode = .scaleAspectFit
            $0.tintColor = Asset.Colors.textAndIconPrimary.color
        }

        iconBackgroundView.layer.cornerRadius = sizeS
        iconBackgroundView.backgroundColor = Asset.Colors.interactiveInputBackground.color
    }

    func setupLayout() {
        addSubview(iconBackgroundView)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        iconBackgroundView.addSubview(iconView)

        iconBackgroundView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(spaceS)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(sizeL)
        }

        iconView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(sizeM)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(spaceXS)
            $0.leading.equalTo(iconBackgroundView.snp.trailing).offset(spaceS)
            $0.trailing.equalToSuperview().inset(spaceS)
        }

        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(spaceXXS)
            $0.leading.trailing.equalTo(titleLabel)
            $0.bottom.lessThanOrEqualToSuperview().inset(spaceXS)
        }
    }

    @objc
    func handleTap() {
        tapCommand.execute()
    }
}
