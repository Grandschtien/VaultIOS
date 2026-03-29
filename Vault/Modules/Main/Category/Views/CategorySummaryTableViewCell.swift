//
//  CategorySummaryTableViewCell.swift
//  Vault
//
//  Created by Егор Шкарин on 29.03.2026.
//

import UIKit
import SnapKit

final class CategorySummaryTableViewCell: UITableViewCell {
    private let summaryView = CategorySummaryView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        contentView.addSubview(summaryView)

        summaryView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with viewModel: CategoryViewModel.SummaryViewModel) {
        summaryView.configure(with: viewModel)
    }
}
