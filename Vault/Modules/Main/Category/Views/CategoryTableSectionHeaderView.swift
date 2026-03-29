//
//  CategoryTableSectionHeaderView.swift
//  Vault
//
//  Created by Егор Шкарин on 29.03.2026.
//

import UIKit
import SnapKit

final class CategoryTableSectionHeaderView: UIView, LayoutScaleProviding {
    private let titleLabel = Label()

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
        titleLabel.apply(viewModel)
    }
}

private extension CategoryTableSectionHeaderView {
    func setupViews() {
        backgroundColor = Asset.Colors.backgroundPrimary.color
    }

    func setupLayout() {
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.bottom.equalToSuperview().inset(spaceXXS)
        }
    }
}
