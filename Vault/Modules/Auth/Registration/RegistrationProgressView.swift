// Created by Egor Shkarin 18.03.2026

import UIKit
import SnapKit

final class RegistrationProgressView: UIView, LayoutScaleProviding {
    private let trackView = UIView()
    private let fillView = UIView()
    private var fillWidthConstraint: Constraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(_ viewModel: RegistrationViewModel.ProgressViewModel) {
        let clampedValue = min(max(.zero, viewModel.value), 1)
        fillWidthConstraint?.deactivate()

        fillView.snp.makeConstraints { make in
            fillWidthConstraint = make.width.equalTo(trackView.snp.width).multipliedBy(clampedValue).constraint
        }

        UIView.animate(withDuration: 0.2) {
            self.layoutIfNeeded()
        }
    }
}

private extension RegistrationProgressView {
    func setupViews() {
        trackView.backgroundColor = Asset.Colors.textAndIconPlaceseholder.color.withAlphaComponent(0.3)
        trackView.layer.cornerRadius = spaceXXS

        fillView.backgroundColor = Asset.Colors.interactiveElemetsPrimary.color
        fillView.layer.cornerRadius = spaceXXS
    }

    func setupLayout() {
        addSubview(trackView)
        trackView.addSubview(fillView)

        trackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(spaceXS)
        }

        fillView.snp.makeConstraints { make in
            make.top.bottom.leading.equalToSuperview()
            fillWidthConstraint = make.width.equalTo(0).constraint
        }
    }
}
