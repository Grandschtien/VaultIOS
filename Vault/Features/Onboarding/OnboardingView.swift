// Created by Egor Shkarin 11.03.2026

import UIKit
import SnapKit

final class OnboardingView: UIView, LayoutScaleProviding {
    private var viewModel: OnboardingViewModel = .init()

    private let imageScrollView = UIScrollView()
    private let pagesStackView = UIStackView()
    private let titleLabel = Label()
    private let subtitleLabel = Label()
    private let primaryButton = Button()
    private let pill = PillView()
    private let pageControl = PageControl(viewModel: OnboardingViewModel().pageControl)

    private var pageViews: [UIView] = []
    private var lastNotifiedPage: Int = .zero

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupLayout()
        configureBindings()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard !viewModel.pages.isEmpty else {
            return
        }

        guard !imageScrollView.isTracking, !imageScrollView.isDragging, !imageScrollView.isDecelerating else {
            return
        }

        let currentPage = clamp(page: viewModel.pageControl.currentPage)
        let targetOffset = CGFloat(currentPage) * max(imageScrollView.bounds.width, 1)
        if abs(imageScrollView.contentOffset.x - targetOffset) > 0.5 {
            imageScrollView.setContentOffset(CGPoint(x: targetOffset, y: .zero), animated: false)
        }
    }
}

extension OnboardingView {
    func configure(with viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
        
        buildPages(with: viewModel.pages)
        titleLabel.apply(viewModel.title)
        subtitleLabel.apply(viewModel.subtitle)
        applyPageControl(with: viewModel.pageControl)
        primaryButton.apply(viewModel.primaryButton)
        pill.apply(viewModel: viewModel.pillViewModel)
        lastNotifiedPage = clamp(page: viewModel.pageControl.currentPage)
    }

    func scrollToPage(_ page: Int, animated: Bool) {
        guard !viewModel.pages.isEmpty else {
            return
        }

        let clampedPage = clamp(page: page)
        let pageWidth = max(imageScrollView.bounds.width, 1)
        imageScrollView.setContentOffset(
            CGPoint(
                x: CGFloat(clampedPage) * pageWidth,
                y: .zero
            ),
            animated: animated
        )
    }
}

private extension OnboardingView {
    func setupViews() {
        backgroundColor = Asset.Colors.backgroundPrimary.color

        imageScrollView.showsVerticalScrollIndicator = false
        imageScrollView.showsHorizontalScrollIndicator = false
        imageScrollView.isPagingEnabled = true
        imageScrollView.alwaysBounceVertical = false
        imageScrollView.alwaysBounceHorizontal = false
        imageScrollView.delegate = self

        pagesStackView.axis = .horizontal
        pagesStackView.alignment = .fill
        pagesStackView.distribution = .fill
        pagesStackView.spacing = .zero
    }

    func setupLayout() {
        addSubview(imageScrollView)
        imageScrollView.addSubview(pagesStackView)
        addSubview(pill)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(pageControl)
        addSubview(primaryButton)

        imageScrollView.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide).offset(spaceS)
            $0.leading.trailing.equalToSuperview().inset(spaceS)
            $0.height.equalTo(imageScrollView.snp.width).multipliedBy(0.9).priority(.high)
        }

        pagesStackView.snp.makeConstraints {
            $0.edges.equalTo(imageScrollView.contentLayoutGuide)
            $0.height.equalTo(imageScrollView.frameLayoutGuide)
        }
        
        pill.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(imageScrollView.snp.bottom).offset(spaceL)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(pill.snp.bottom).offset(spaceM)
            $0.leading.trailing.equalToSuperview().inset(spaceS)
        }

        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(spaceS)
            $0.leading.trailing.equalToSuperview().inset(spaceL)
        }
        
        pageControl.snp.makeConstraints {
            $0.top.equalTo(subtitleLabel.snp.bottom).offset(spaceS)
            $0.centerX.equalToSuperview()
        }

        primaryButton.snp.makeConstraints {
            $0.top.equalTo(pageControl.snp.bottom).offset(spaceL)
            $0.leading.trailing.equalToSuperview().inset(spaceL)
        }
    }

    func configureBindings() {
        pageControl.connect(to: imageScrollView)
        pageControl.onPageSelected = { [weak self] page in
            self?.notifyCurrentPageChanged(page)
        }
    }

    func buildPages(with pages: [OnboardingViewModel.PageViewModel]) {
        for page in pages {
            let pageView = UIView()
            let imageView = UIImageView(image: image(for: page.image))
            imageView.contentMode = .scaleAspectFit

            pageView.addSubview(imageView)
            imageView.snp.makeConstraints {
                $0.edges.equalToSuperview().inset(spaceS)
            }

            pagesStackView.addArrangedSubview(pageView)
            pageView.snp.makeConstraints {
                $0.width.equalTo(imageScrollView.frameLayoutGuide)
            }

            pageViews.append(pageView)
        }
    }

    func applyPageControl(with viewModel: PageControl.PageControlViewModel) {
        pageControl.apply(viewModel, animated: true)
    }

    func notifyCurrentPageChanged(_ page: Int) {
        let page = clamp(page: page)
        guard page != lastNotifiedPage else {
            return
        }

        lastNotifiedPage = page
        viewModel.currentPageChangedCommand?.execute(page)
    }

    func resolvedCurrentPage() -> Int {
        guard !viewModel.pages.isEmpty else {
            return .zero
        }

        let pageWidth = max(imageScrollView.bounds.width, 1)
        let rawPage = Int(round(imageScrollView.contentOffset.x / pageWidth))
        return clamp(page: rawPage)
    }

    func clamp(page: Int) -> Int {
        guard !viewModel.pages.isEmpty else {
            return .zero
        }

        return min(max(.zero, page), viewModel.pages.count - 1)
    }

    func image(for image: OnboardingViewModel.Image) -> UIImage {
        switch image {
        case .onboarding1:
            return Asset.Images.onboarding1.image
        case .onboarding2:
            return Asset.Images.onboarding2.image
        case .onboarding3:
            return Asset.Images.onboarding3.image
        }
    }

}

extension OnboardingView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        notifyCurrentPageChanged(resolvedCurrentPage())
    }
}
