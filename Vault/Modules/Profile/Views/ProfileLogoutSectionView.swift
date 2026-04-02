import UIKit
import SnapKit
import SkeletonView

final class ProfileLogoutSectionView: UIView, LayoutScaleProviding {
    private let button = Button()
    private let skeletonView = UIView()

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

    func configure(with viewModel: Button.ButtonViewModel) {
        button.apply(viewModel)
        button.layer.borderWidth = 1
        button.layer.borderColor = Asset.Colors.errorColor.color.withAlphaComponent(0.2).cgColor
    }

    func setLoading(_ isLoading: Bool) {
        if isLoading {
            showSkeleton()
        } else {
            hideSkeleton()
        }
    }
}

private extension ProfileLogoutSectionView {
    func setupViews() {
        skeletonView.layer.cornerRadius = sizeL
        skeletonView.backgroundColor = Asset.Colors.interactiveInputBackground.color
        skeletonView.isSkeletonable = true
        skeletonView.skeletonCornerRadius = Float(sizeL)
        skeletonView.isHidden = true
    }

    func setupLayout() {
        addSubview(button)
        addSubview(skeletonView)

        button.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        skeletonView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    func showSkeleton() {
        guard !isSkeletonAnimating else {
            return
        }

        isSkeletonAnimating = true
        button.isHidden = true
        skeletonView.isHidden = false
        skeletonView.showAnimatedGradientSkeleton()
    }

    func hideSkeleton() {
        guard isSkeletonAnimating else {
            return
        }

        isSkeletonAnimating = false
        button.isHidden = false
        skeletonView.isHidden = true
        skeletonView.hideSkeleton()
    }
}
