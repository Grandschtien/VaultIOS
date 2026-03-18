// Created by Egor Shkarin 18.03.2026

import UIKit
import SnapKit

final class RegistrationCurrencyStepView: UIView, LayoutScaleProviding {
    private struct Section {
        let title: Label.LabelViewModel?
        let rows: [RegistrationViewModel.CurrencyRowViewModel]
    }

    private let titleLabel = Label()
    private let searchField = TextField()
    private let errorLabel = Label()
    private let tableView = UITableView(frame: .zero, style: .plain)

    private var sections: [Section] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with viewModel: RegistrationViewModel.CurrencyViewModel) {
        titleLabel.apply(viewModel.title)
        searchField.apply(viewModel.searchField)

        if let errorViewModel = viewModel.errorLabel {
            errorLabel.isHidden = false
            errorLabel.apply(errorViewModel)
        } else {
            errorLabel.isHidden = true
        }

        sections = [
            Section(
                title: viewModel.popularSectionTitle,
                rows: viewModel.popularRows
            ),
            Section(
                title: viewModel.otherSectionTitle,
                rows: viewModel.otherRows
            )
        ]
        .filter { !$0.rows.isEmpty }

        tableView.reloadData()
    }
}

private extension RegistrationCurrencyStepView {
    func setupViews() {
        errorLabel.isHidden = true

        tableView.register(
            RegistrationCurrencyCell.self,
            forCellReuseIdentifier: RegistrationCurrencyCell.reuseId
        )
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 72
        tableView.sectionHeaderTopPadding = .zero
    }

    func setupLayout() {
        [titleLabel, searchField, errorLabel, tableView].forEach { addSubview($0) }

        titleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        searchField.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(spaceL)
            make.leading.trailing.equalToSuperview()
        }

        errorLabel.snp.makeConstraints { make in
            make.top.equalTo(searchField.snp.bottom).offset(spaceXXS)
            make.leading.trailing.equalToSuperview()
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(errorLabel.snp.bottom).offset(spaceS)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
}

extension RegistrationCurrencyStepView: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].rows.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: RegistrationCurrencyCell.reuseId,
            for: indexPath
        ) as? RegistrationCurrencyCell
        else {
            return UITableViewCell()
        }

        cell.configure(with: sections[indexPath.section].rows[indexPath.row])

        return cell
    }
}

extension RegistrationCurrencyStepView: UITableViewDelegate {
    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        tableView.deselectRow(at: indexPath, animated: true)

        sections[indexPath.section].rows[indexPath.row].tapCommand.execute()
    }

    func tableView(
        _ tableView: UITableView,
        viewForHeaderInSection section: Int
    ) -> UIView? {
        guard let titleViewModel = sections[section].title else {
            return nil
        }

        let headerView = UIView()
        headerView.backgroundColor = .clear

        let titleLabel = Label()
        titleLabel.apply(titleViewModel)
        headerView.addSubview(titleLabel)

        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().inset(spaceXXS)
            make.top.equalToSuperview().offset(spaceXXS)
        }

        return headerView
    }

    func tableView(
        _ tableView: UITableView,
        heightForHeaderInSection section: Int
    ) -> CGFloat {
        sections[section].title == nil ? .leastNormalMagnitude : 24
    }
}
