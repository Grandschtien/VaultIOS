//
//  ExpenseCollectionViewCell.swift
//  Vault
//
//  Created by Егор Шкарин on 29.03.2026.
//

import UIKit
import SnapKit

final class ExpenseCollectionViewCell: UICollectionViewCell {
    static let reuseId = "ExpenseCollectionViewCell"

    private(set) var viewModel: ExpenseView.ViewModel = .init()

    private let expenseView = ExpenseView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with viewModel: ExpenseView.ViewModel) {
        self.viewModel = viewModel
        expenseView.configure(with: viewModel)
    }
}

private extension ExpenseCollectionViewCell {
    func setupViews() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }

    func setupLayout() {
        contentView.addSubview(expenseView)
        expenseView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

final class ExpenseTableViewCell: UITableViewCell {
    static let reuseId = "ExpenseTableViewCell"

    private(set) var viewModel: ExpenseView.ViewModel = .init()

    private let expenseView = ExpenseView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with viewModel: ExpenseView.ViewModel) {
        self.viewModel = viewModel
        expenseView.configure(with: viewModel)
    }
}

private extension ExpenseTableViewCell {
    func setupViews() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
    }

    func setupLayout() {
        contentView.addSubview(expenseView)
        expenseView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
