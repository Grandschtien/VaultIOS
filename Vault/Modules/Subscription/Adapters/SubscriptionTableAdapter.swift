// Created by Egor Shkarin 11.04.2026

import UIKit
import SnapKit

final class SubscriptionTableAdapter: NSObject, LayoutScaleProviding {
    private enum Constants {
        static let sectionID = "subscription-main-section"
    }

    private var dataSource: UITableViewDiffableDataSource<String, String>?
    private var rowIDs: [String] = []
    private var rowsByID: [String: SubscriptionViewModel.PlanCard] = [:]

    func attach(to tableView: UITableView) {
        tableView.register(SubscriptionPlanCell.self)
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = sizeXXL
        tableView.delegate = self

        dataSource = UITableViewDiffableDataSource<String, String>(
            tableView: tableView,
            cellProvider: { [weak self] tableView, indexPath, itemID in
                guard let self,
                      let row = self.rowsByID[itemID] else {
                    return UITableViewCell()
                }

                let cell = tableView.dequeueReusableCell(
                    SubscriptionPlanCell.self,
                    for: indexPath
                )
                cell.configure(with: row)
                return cell
            }
        )
    }

    func configure(plans: [SubscriptionViewModel.PlanCard]) {
        rowIDs = plans.map { "subscription-plan-\($0.id)" }
        rowsByID = Dictionary(uniqueKeysWithValues: zip(rowIDs, plans).map { ($0.0, $0.1) })

        var snapshot = NSDiffableDataSourceSnapshot<String, String>()
        snapshot.appendSections([Constants.sectionID])
        snapshot.appendItems(rowIDs, toSection: Constants.sectionID)
        dataSource?.apply(snapshot, animatingDifferences: true)
    }
}

extension SubscriptionTableAdapter: UITableViewDelegate {
    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(
        _ tableView: UITableView,
        estimatedHeightForRowAt indexPath: IndexPath
    ) -> CGFloat {
        sizeXXL
    }
}

private final class SubscriptionPlanCell: UITableViewCell, Reusable, LayoutScaleProviding {
    private let cardView = UIView()
    private let titleLabel = Label()
    private let descriptionLabel = Label()
    private let priceLabel = Label()
    private let button = Button()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with viewModel: SubscriptionViewModel.PlanCard) {
        titleLabel.apply(viewModel.title)
        descriptionLabel.apply(viewModel.description)
        priceLabel.apply(viewModel.price)
        button.apply(viewModel.button)
    }
}

private extension SubscriptionPlanCell {
    func setupViews() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = sizeL
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = Asset.Colors.textAndIconPlaceseholder.color
            .withAlphaComponent(0.15)
            .cgColor
    }

    func setupLayout() {
        contentView.addSubview(cardView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(descriptionLabel)
        cardView.addSubview(priceLabel)
        cardView.addSubview(button)

        cardView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalToSuperview().inset(spaceS)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(spaceS)
            make.horizontalEdges.equalToSuperview().inset(spaceS)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(spaceXS)
            make.horizontalEdges.equalToSuperview().inset(spaceS)
        }

        priceLabel.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(spaceS)
            make.horizontalEdges.equalToSuperview().inset(spaceS)
        }

        button.snp.makeConstraints { make in
            make.top.equalTo(priceLabel.snp.bottom).offset(spaceS)
            make.horizontalEdges.equalToSuperview().inset(spaceS)
            make.bottom.equalToSuperview().inset(spaceS)
        }
    }
}
