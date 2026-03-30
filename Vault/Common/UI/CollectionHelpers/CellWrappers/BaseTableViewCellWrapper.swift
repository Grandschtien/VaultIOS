// Created by Codex on 30.03.2026

import UIKit
import SnapKit

class BaseTableViewCellWrapper<
    WrappedView: UIView & ConfigurableCellWrappedView
>: UITableViewCell, Reusable {
    typealias ViewModel = WrappedView.ViewModel

    let wrappedView = WrappedView(frame: .zero)
    private(set) var viewModel: ViewModel!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with viewModel: ViewModel) {
        self.viewModel = viewModel
        wrappedView.configure(with: viewModel)
    }

    func setupViews() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
    }

    func setupLayout() {
        contentView.addSubview(wrappedView)
        setupWrappedViewConstraints()
    }

    func setupWrappedViewConstraints() {
        wrappedView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
