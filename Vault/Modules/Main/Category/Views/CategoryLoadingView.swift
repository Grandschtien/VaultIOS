//
//  CategoryLoadingView.swift
//  Vault
//
//  Created by Егор Шкарин on 29.03.2026.
//

import UIKit
import SnapKit
import SkeletonView

final class CategoryLoadingView: UIView, LayoutScaleProviding {
    private let container = UIStackView()
    private let summaryPlaceholder = UIView()
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
        summaryPlaceholder.showAnimatedGradientSkeleton()
        loadingPlaceholders.forEach { $0.showAnimatedGradientSkeleton() }
    }

    func hideLoading() {
        guard isAnimatingSkeleton else {
            return
        }

        isAnimatingSkeleton = false
        summaryPlaceholder.hideSkeleton()
        loadingPlaceholders.forEach { $0.hideSkeleton() }
    }
}

private extension CategoryLoadingView {
    func setupViews() {
        backgroundColor = .clear
        container.axis = .vertical
        container.alignment = .fill
        container.distribution = .fill
        container.spacing = spaceS

       addSubview(container)

        summaryPlaceholder.isSkeletonable = true
        summaryPlaceholder.layer.cornerRadius = sizeL
        summaryPlaceholder.skeletonCornerRadius = Float(sizeL)
        summaryPlaceholder.backgroundColor = Asset.Colors.interactiveInputBackground.color
        container.addArrangedSubview(summaryPlaceholder)

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

        summaryPlaceholder.snp.makeConstraints { make in
            make.height.equalTo(sizeXXL)
        }

        loadingPlaceholders.forEach { placeholder in
            placeholder.snp.makeConstraints { make in
                make.height.equalTo(sizeXL)
            }
        }
    }
}
