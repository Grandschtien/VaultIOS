import UIKit
import SnapKit
import SkeletonView

final class ProfileHeaderSectionView: UIView, LayoutScaleProviding {
    private let avatarView = UIView()
    private let avatarInitialsLabel = Label()
    private let nameLabel = Label()
    private let membershipLabel = Label()
    private let namePlaceholderView = UIView()
    private let membershipPlaceholderView = UIView()

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
        avatar: ProfileViewModel.Avatar,
        name: Label.LabelViewModel,
        membership: Label.LabelViewModel
    ) {
        avatarView.backgroundColor = avatar.backgroundColor
        avatarInitialsLabel.apply(avatar.initials)
        nameLabel.apply(name)
        membershipLabel.apply(membership)
    }

    func setLoading(_ isLoading: Bool) {
        if isLoading {
            showSkeleton()
        } else {
            hideSkeleton()
        }
    }
}

private extension ProfileHeaderSectionView {
    func setupViews() {
        avatarView.layer.cornerRadius = sizeXXL / 2
        avatarView.clipsToBounds = true
        avatarView.isSkeletonable = true
        avatarView.skeletonCornerRadius = Float(sizeXXL / 2)

        namePlaceholderView.layer.cornerRadius = sizeS
        namePlaceholderView.backgroundColor = Asset.Colors.interactiveInputBackground.color
        namePlaceholderView.isSkeletonable = true
        namePlaceholderView.skeletonCornerRadius = Float(sizeS)
        namePlaceholderView.isHidden = true

        membershipPlaceholderView.layer.cornerRadius = sizeS
        membershipPlaceholderView.backgroundColor = Asset.Colors.interactiveInputBackground.color
        membershipPlaceholderView.isSkeletonable = true
        membershipPlaceholderView.skeletonCornerRadius = Float(sizeS)
        membershipPlaceholderView.isHidden = true
    }

    func setupLayout() {
        addSubview(avatarView)
        addSubview(nameLabel)
        addSubview(membershipLabel)
        addSubview(namePlaceholderView)
        addSubview(membershipPlaceholderView)
        avatarView.addSubview(avatarInitialsLabel)

        avatarView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.centerX.equalToSuperview()
            $0.size.equalTo(sizeXXL)
        }

        avatarInitialsLabel.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        nameLabel.snp.makeConstraints {
            $0.top.equalTo(avatarView.snp.bottom).offset(spaceS)
            $0.horizontalEdges.equalToSuperview().inset(spaceS)
        }

        membershipLabel.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(spaceXXS)
            $0.horizontalEdges.equalToSuperview().inset(spaceS)
            $0.bottom.equalToSuperview()
        }

        namePlaceholderView.snp.makeConstraints {
            $0.top.equalTo(avatarView.snp.bottom).offset(spaceS)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(sizeXXL)
            $0.height.equalTo(sizeS)
        }

        membershipPlaceholderView.snp.makeConstraints {
            $0.top.equalTo(namePlaceholderView.snp.bottom).offset(spaceXXS)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(sizeXL)
            $0.height.equalTo(sizeS)
            $0.bottom.equalToSuperview()
        }
    }

    func showSkeleton() {
        guard !isSkeletonAnimating else {
            return
        }

        isSkeletonAnimating = true
        nameLabel.isHidden = true
        membershipLabel.isHidden = true
        namePlaceholderView.isHidden = false
        membershipPlaceholderView.isHidden = false

        [avatarView, namePlaceholderView, membershipPlaceholderView].forEach {
            $0.showAnimatedGradientSkeleton()
        }
    }

    func hideSkeleton() {
        guard isSkeletonAnimating else {
            return
        }

        isSkeletonAnimating = false
        nameLabel.isHidden = false
        membershipLabel.isHidden = false
        namePlaceholderView.isHidden = true
        membershipPlaceholderView.isHidden = true

        [avatarView, namePlaceholderView, membershipPlaceholderView].forEach {
            $0.hideSkeleton()
        }
    }
}
