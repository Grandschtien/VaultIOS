import UIKit
import SnapKit
import SkeletonView

final class ProfilePlanCardSectionView: UIView, LayoutScaleProviding {
    private let cardView = UIView()
    private let iconView = UIImageView()
    private let textStackView = UIStackView()
    private let titleLabel = Label()
    private let subtitleLabel = Label()
    private let usageLabel = Label()

    private var isSkeletonAnimating = false
    private var isUsageHidden = true
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

    func configure(with viewModel: ProfileViewModel.PlanCard) {
        iconView.image = viewModel.icon
        titleLabel.apply(viewModel.title)
        subtitleLabel.apply(viewModel.subtitle)
        usageLabel.apply(viewModel.usage ?? .init())
        isUsageHidden = viewModel.usage == nil
        usageLabel.isHidden = isUsageHidden
        tapCommand = viewModel.tapCommand
        isUserInteractionEnabled = viewModel.tapCommand != .nope
    }

    func setLoading(_ isLoading: Bool) {
        if isLoading {
            showSkeleton()
        } else {
            hideSkeleton()
        }
    }
}

private extension ProfilePlanCardSectionView {
    func setupViews() {
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapRecognizer)
        cardView.backgroundColor = Asset.Colors.interactiveElemetsPrimary.color
        cardView.layer.cornerRadius = sizeL
        cardView.clipsToBounds = true
        cardView.isSkeletonable = true
        cardView.skeletonCornerRadius = Float(sizeL)

        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = Asset.Colors.textAndIconPrimaryInverted.color

        textStackView.axis = .vertical
        textStackView.alignment = .fill
        textStackView.distribution = .fill
        textStackView.spacing = spaceXXS
    }

    func setupLayout() {
        addSubview(cardView)
        cardView.addSubview(iconView)
        cardView.addSubview(textStackView)

        textStackView.addArrangedSubview(titleLabel)
        textStackView.addArrangedSubview(subtitleLabel)
        textStackView.addArrangedSubview(usageLabel)

        cardView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.greaterThanOrEqualTo(sizeXL)
        }

        iconView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(spaceS)
            $0.top.equalToSuperview().offset(spaceS)
            $0.size.equalTo(sizeM)
        }

        textStackView.snp.makeConstraints {
            $0.leading.equalTo(iconView.snp.trailing).offset(spaceXS)
            $0.trailing.equalToSuperview().inset(spaceS)
            $0.top.equalToSuperview().offset(spaceS)
            $0.bottom.equalToSuperview().inset(spaceS)
        }
    }

    func showSkeleton() {
        guard !isSkeletonAnimating else {
            return
        }

        isSkeletonAnimating = true
        iconView.isHidden = true
        titleLabel.isHidden = true
        subtitleLabel.isHidden = true
        usageLabel.isHidden = true
        cardView.showAnimatedGradientSkeleton()
    }

    func hideSkeleton() {
        guard isSkeletonAnimating else {
            return
        }

        isSkeletonAnimating = false
        iconView.isHidden = false
        titleLabel.isHidden = false
        subtitleLabel.isHidden = false
        usageLabel.isHidden = isUsageHidden
        cardView.hideSkeleton()
    }

    @objc
    func handleTap() {
        tapCommand.execute()
    }
}
