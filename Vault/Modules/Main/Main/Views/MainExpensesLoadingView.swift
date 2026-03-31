// Created by Egor Shkarin on 30.03.2026

import UIKit
import SnapKit
import SkeletonView

final class MainExpensesLoadingView: UIView, LayoutScaleProviding {
    private let container = UIStackView()
    private let loadingPlaceholders = (0..<5).map { _ in UIView() }

    private var isAnimatingSkeleton = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showLoading() {
        guard !isAnimatingSkeleton else {
            return
        }

        isAnimatingSkeleton = true
        loadingPlaceholders.forEach { $0.showAnimatedGradientSkeleton() }
    }

    func hideLoading() {
        guard isAnimatingSkeleton else {
            return
        }

        isAnimatingSkeleton = false
        loadingPlaceholders.forEach { $0.hideSkeleton() }
    }
}

private extension MainExpensesLoadingView {
    func setupViews() {
        backgroundColor = .clear
        container.axis = .vertical
        container.alignment = .fill
        container.distribution = .fill
        container.spacing = spaceS

        addSubview(container)

        loadingPlaceholders.forEach { placeholder in
            placeholder.isSkeletonable = true
            placeholder.layer.cornerRadius = sizeL
            placeholder.skeletonCornerRadius = Float(sizeL)
            placeholder.backgroundColor = Asset.Colors.interactiveInputBackground.color
            container.addArrangedSubview(placeholder)
        }
    }

    func setupLayout() {
        container.snp.makeConstraints { make in
            make.verticalEdges.equalToSuperview()
            make.horizontalEdges.equalToSuperview().inset(spaceXS)
        }

        loadingPlaceholders.forEach { placeholder in
            placeholder.snp.makeConstraints { make in
                make.height.equalTo(sizeXL)
            }
        }
    }
}
