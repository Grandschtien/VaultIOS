// Created by Egor Shkarin 29.03.2026

import UIKit
import SnapKit

final class ProfileView: UIView, LayoutScaleProviding {
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let contentStackView = UIStackView()
    private let errorView = FullScreenCommonErrorView()
    private let savingContainerView = UIView()
    private let savingIndicatorView = UIActivityIndicatorView(style: .medium)

    private let headerSectionView = ProfileHeaderSectionView()
    private let planSectionView = ProfilePlanCardSectionView()
    private let generalSectionView = ProfileGeneralSectionView()
    private let logoutSectionView = ProfileLogoutSectionView()
    private let versionSectionView = ProfileVersionSectionView()

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

extension ProfileView {
    func configure(with viewModel: ProfileViewModel) {
        switch viewModel.state {
        case let .loading(content):
            errorView.isHidden = true
            scrollView.isHidden = false
            apply(content)
            setLoading(true)
            setSaving(content.isSavingCurrency)

        case let .loaded(content):
            errorView.isHidden = true
            scrollView.isHidden = false
            apply(content)
            setLoading(false)
            setSaving(content.isSavingCurrency)

        case let .error(errorViewModel):
            setLoading(false)
            setSaving(false)
            scrollView.isHidden = true
            errorView.isHidden = false
            errorView.apply(errorViewModel)
        }
    }
}

private extension ProfileView {
    func apply(_ content: ProfileViewModel.Content) {
        headerSectionView.configure(
            avatar: content.avatar,
            name: content.name,
            membership: content.membership
        )
        planSectionView.configure(with: content.plan)
        generalSectionView.configure(
            title: content.generalSectionTitle,
            rows: content.rows
        )
        logoutSectionView.configure(with: content.logoutButton)
        versionSectionView.configure(with: content.version)
    }

    func setupViews() {
        backgroundColor = Asset.Colors.backgroundPrimary.color

        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        errorView.isHidden = true
        savingContainerView.backgroundColor = Asset.Colors.backgroundPrimary.color.withAlphaComponent(0.35)
        savingContainerView.isHidden = true
        savingIndicatorView.hidesWhenStopped = true
        savingIndicatorView.color = Asset.Colors.interactiveElemetsPrimary.color

        contentStackView.axis = .vertical
        contentStackView.alignment = .fill
        contentStackView.distribution = .fill
        contentStackView.spacing = spaceM
    }

    func setupLayout() {
        addSubview(scrollView)
        addSubview(errorView)
        addSubview(savingContainerView)
        scrollView.addSubview(contentView)
        contentView.addSubview(contentStackView)
        savingContainerView.addSubview(savingIndicatorView)

        contentStackView.addArrangedSubview(headerSectionView)
        contentStackView.addArrangedSubview(planSectionView)
        contentStackView.addArrangedSubview(generalSectionView)
        contentStackView.addArrangedSubview(logoutSectionView)
        contentStackView.addArrangedSubview(versionSectionView)

        scrollView.snp.makeConstraints {
            $0.edges.equalTo(safeAreaLayoutGuide)
        }

        errorView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        savingContainerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollView.snp.width)
        }

        contentStackView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(spaceS)
            $0.horizontalEdges.equalToSuperview().inset(spaceS)
            $0.bottom.equalToSuperview().inset(spaceS)
        }
        logoutSectionView.snp.makeConstraints {
            $0.height.equalTo(sizeXL)
        }

        versionSectionView.snp.makeConstraints {
            $0.height.equalTo(sizeM)
        }

        savingIndicatorView.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }

    func setLoading(_ isLoading: Bool) {
        headerSectionView.setLoading(isLoading)
        planSectionView.setLoading(isLoading)
        generalSectionView.setLoading(isLoading)
        logoutSectionView.setLoading(isLoading)
        versionSectionView.setLoading(isLoading)
    }

    func setSaving(_ isSaving: Bool) {
        savingContainerView.isHidden = !isSaving
        scrollView.isUserInteractionEnabled = !isSaving

        if isSaving {
            savingIndicatorView.startAnimating()
        } else {
            savingIndicatorView.stopAnimating()
        }
    }
}
