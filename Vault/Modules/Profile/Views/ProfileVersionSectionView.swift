import UIKit
import SnapKit
import SkeletonView

final class ProfileVersionSectionView: UIView, LayoutScaleProviding {
    private let label = Label()
    private let placeholderView = UIView()

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

    func configure(with viewModel: Label.LabelViewModel) {
        label.apply(viewModel)
    }

    func setLoading(_ isLoading: Bool) {
        if isLoading {
            showSkeleton()
        } else {
            hideSkeleton()
        }
    }
}

private extension ProfileVersionSectionView {
    func setupViews() {
        placeholderView.layer.cornerRadius = sizeS
        placeholderView.backgroundColor = Asset.Colors.interactiveInputBackground.color
        placeholderView.isSkeletonable = true
        placeholderView.skeletonCornerRadius = Float(sizeS)
        placeholderView.isHidden = true
    }

    func setupLayout() {
        addSubview(label)
        addSubview(placeholderView)

        label.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        placeholderView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.equalTo(sizeXXL)
            $0.height.equalTo(sizeS)
        }
    }

    func showSkeleton() {
        guard !isSkeletonAnimating else {
            return
        }

        isSkeletonAnimating = true
        label.isHidden = true
        placeholderView.isHidden = false
        placeholderView.showAnimatedGradientSkeleton()
    }

    func hideSkeleton() {
        guard isSkeletonAnimating else {
            return
        }

        isSkeletonAnimating = false
        label.isHidden = false
        placeholderView.isHidden = true
        placeholderView.hideSkeleton()
    }
}
