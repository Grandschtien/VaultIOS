import UIKit
import SnapKit
import SkeletonView

final class ProfilePlanCardSectionView: UIView, LayoutScaleProviding {
    private let cardView = UIView()
    private let iconView = UIImageView()
    private let titleLabel = Label()
    private let subtitleLabel = Label()

    private var isSkeletonAnimating = false
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
    }

    func setupLayout() {
        addSubview(cardView)
        cardView.addSubview(iconView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(subtitleLabel)

        cardView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.greaterThanOrEqualTo(sizeXL)
        }

        iconView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(spaceS)
            $0.top.equalToSuperview().offset(spaceS)
            $0.size.equalTo(sizeM)
        }

        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(iconView.snp.trailing).offset(spaceXS)
            $0.trailing.equalToSuperview().inset(spaceS)
            $0.top.equalToSuperview().offset(spaceS)
        }

        subtitleLabel.snp.makeConstraints {
            $0.leading.equalTo(titleLabel)
            $0.trailing.equalToSuperview().inset(spaceS)
            $0.top.equalTo(titleLabel.snp.bottom).offset(spaceXXS)
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
        cardView.hideSkeleton()
    }

    @objc
    func handleTap() {
        tapCommand.execute()
    }
}
