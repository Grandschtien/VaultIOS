// Created by Egor Shkarin 08.04.2026

import UIKit
import SnapKit

final class SubscriptionView: UIView, LayoutScaleProviding {
    private let tableAdapter = SubscriptionTableAdapter()
    private let headerView = AddExpenseSheetHeaderView()
    private let loadingView = UIActivityIndicatorView(style: .medium)
    private let overlayView = UIView()
    private let overlayCardView = UIView()
    private let overlayStackView = UIStackView()
    private let overlayLoadingView = UIActivityIndicatorView(style: .medium)
    private let overlayMessageLabel = Label()
    private let errorView = FullScreenCommonErrorView()
    private let titleLabel = Label()
    private let subtitleLabel = Label()
    private let currentPlanView = SubscriptionCurrentPlanCardView()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let restoreButton = Button()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SubscriptionView {
    func configure(with viewModel: SubscriptionViewModel) {
        headerView.apply(viewModel.header)
        setOverlay(
            isLoading: viewModel.isOverlayLoading,
            message: viewModel.overlayMessage
        )

        switch viewModel.state {
        case .loading:
            loadingView.startAnimating()
            loadingView.isHidden = false
            errorView.isHidden = true
            setContentHidden(true)

        case let .loaded(content):
            loadingView.stopAnimating()
            loadingView.isHidden = true
            errorView.isHidden = true
            setContentHidden(false)
            apply(content)

        case let .error(errorViewModel):
            loadingView.stopAnimating()
            loadingView.isHidden = true
            errorView.isHidden = false
            setContentHidden(true)
            errorView.apply(errorViewModel)
        }
    }
}

private extension SubscriptionView {
    func apply(_ content: SubscriptionViewModel.Content) {
        titleLabel.apply(content.title)
        subtitleLabel.apply(content.subtitle)
        currentPlanView.configure(with: content.currentPlan)
        tableAdapter.configure(plans: content.plans)
        restoreButton.apply(content.restoreButton)
    }

    func setupViews() {
        backgroundColor = Asset.Colors.backgroundPrimary.color

        loadingView.hidesWhenStopped = true
        loadingView.color = Asset.Colors.interactiveElemetsPrimary.color
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.12)
        overlayView.isHidden = true
        overlayCardView.backgroundColor = Asset.Colors.backgroundPrimary.color
        overlayCardView.layer.cornerRadius = sizeL
        overlayStackView.axis = .vertical
        overlayStackView.alignment = .center
        overlayStackView.spacing = spaceS
        overlayLoadingView.hidesWhenStopped = true
        overlayLoadingView.color = Asset.Colors.interactiveElemetsPrimary.color
        overlayMessageLabel.isHidden = true
        errorView.isHidden = true
        titleLabel.isHidden = true
        subtitleLabel.isHidden = true
        currentPlanView.isHidden = true
        tableView.isHidden = true
        restoreButton.isHidden = true

        tableAdapter.attach(to: tableView)
        tableView.sectionHeaderTopPadding = .zero
        tableView.contentInset = UIEdgeInsets(
            top: spaceXS,
            left: .zero,
            bottom: spaceS,
            right: .zero
        )
    }

    func setupLayout() {
        addSubview(headerView)
        addSubview(loadingView)
        addSubview(errorView)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(currentPlanView)
        addSubview(tableView)
        addSubview(restoreButton)
        addSubview(overlayView)
        overlayView.addSubview(overlayCardView)
        overlayCardView.addSubview(overlayStackView)
        overlayStackView.addArrangedSubview(overlayLoadingView)
        overlayStackView.addArrangedSubview(overlayMessageLabel)
        overlayMessageLabel.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
        }

        headerView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide)
            make.horizontalEdges.equalToSuperview()
        }

        loadingView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        errorView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(spaceL)
            make.horizontalEdges.equalToSuperview().inset(spaceS)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(spaceL)
            make.horizontalEdges.equalToSuperview().inset(spaceS)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(spaceXS)
            make.horizontalEdges.equalToSuperview().inset(spaceS)
        }

        currentPlanView.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(spaceS)
            make.horizontalEdges.equalToSuperview().inset(spaceS)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(currentPlanView.snp.bottom).offset(spaceS)
            make.horizontalEdges.equalToSuperview().inset(spaceS)
            make.bottom.equalTo(restoreButton.snp.top).offset(-spaceXS)
        }

        restoreButton.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(spaceS)
            make.bottom.equalTo(safeAreaLayoutGuide).inset(spaceS)
        }

        overlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        overlayCardView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.horizontalEdges
                .greaterThanOrEqualToSuperview()
                .inset(spaceS)
        }

        overlayStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(spaceS)
        }
    }

    func setContentHidden(_ isHidden: Bool) {
        titleLabel.isHidden = isHidden
        subtitleLabel.isHidden = isHidden
        currentPlanView.isHidden = isHidden
        tableView.isHidden = isHidden
        restoreButton.isHidden = isHidden
    }

    func setOverlay(
        isLoading: Bool,
        message: Label.LabelViewModel?
    ) {
        overlayView.isHidden = !isLoading
        overlayMessageLabel.isHidden = message == nil

        if let message {
            overlayMessageLabel.apply(message)
        }

        if isLoading {
            overlayLoadingView.startAnimating()
        } else {
            overlayLoadingView.stopAnimating()
        }
    }
}

private final class SubscriptionCurrentPlanCardView: UIView, LayoutScaleProviding {
    private let cardView = UIView()
    private let titleLabel = Label()
    private let planTitleLabel = Label()
    private let descriptionLabel = Label()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with viewModel: SubscriptionViewModel.CurrentPlanCard) {
        titleLabel.apply(viewModel.title)
        planTitleLabel.apply(viewModel.planTitle)
        descriptionLabel.apply(viewModel.description)
    }
}

private extension SubscriptionCurrentPlanCardView {
    func setupViews() {
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = sizeL
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = Asset.Colors.textAndIconPlaceseholder.color
            .withAlphaComponent(0.15)
            .cgColor
    }

    func setupLayout() {
        addSubview(cardView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(planTitleLabel)
        cardView.addSubview(descriptionLabel)

        cardView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(spaceS)
            make.horizontalEdges.equalToSuperview().inset(spaceS)
        }

        planTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(spaceXS)
            make.horizontalEdges.equalToSuperview().inset(spaceS)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(planTitleLabel.snp.bottom).offset(spaceXS)
            make.horizontalEdges.equalToSuperview().inset(spaceS)
            make.bottom.equalToSuperview().inset(spaceS)
        }
    }
}
