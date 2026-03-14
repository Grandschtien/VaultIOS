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
    
    private let pages = OnboardingModel.pages

    private var pageViews: [UIView] = []
    private var lastNotifiedPage: Int = .zero

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

extension OnboardingView {
    func configure(with viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
        
//        scrollToPage(viewModel.selectedPage, animated: true)
        pageControl.apply(viewModel.pageControl, animated: true)
        primaryButton.apply(viewModel.primaryButton)
    }

    func scrollToPage(_ page: Int, animated: Bool) {
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
        imageScrollView.isScrollEnabled = false
        
        pagesStackView.axis = .horizontal
        pagesStackView.alignment = .fill
        pagesStackView.distribution = .fill
        pagesStackView.spacing = .zero
        pageControl.isUserInteractionEnabled = false
    }

    func setupLayout() {
        addSubview(imageScrollView)
        imageScrollView.addSubview(pagesStackView)
        addSubview(pageControl)
        addSubview(primaryButton)

        imageScrollView.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide).offset(spaceM)
            $0.leading.trailing.equalToSuperview().inset(spaceS)
            $0.height.equalTo(UIScreen.main.bounds.height * 0.6)
        }

        pagesStackView.snp.makeConstraints {
            $0.edges.equalTo(imageScrollView.contentLayoutGuide)
            $0.height.equalTo(imageScrollView.frameLayoutGuide)
        }

        pageControl.snp.makeConstraints {
            $0.top.equalTo(imageScrollView.snp.bottom).offset(spaceM)
            $0.centerX.equalToSuperview()
        }

        primaryButton.snp.makeConstraints {
            $0.top.equalTo(pageControl.snp.bottom).offset(spaceL)
            $0.leading.trailing.equalToSuperview().inset(spaceL)
        }

        buildPages(with: pages)
    }

    func buildPages(with pages: [OnboardingModel]) {
        guard pageViews.isEmpty else { return }

        for page in pages {
            let pageView = UIView()

            let imageView = UIImageView(image: page.image)
            imageView.contentMode = .scaleAspectFit

            let titleLabel = Label()
            titleLabel.apply(page.title)

            let subtitleLabel = Label()
            subtitleLabel.apply(page.subtitle)

            let pill = PillView()
            pill.apply(viewModel: page.pill)

            pageView.addSubview(imageView)
            pageView.addSubview(pill)
            pageView.addSubview(titleLabel)
            pageView.addSubview(subtitleLabel)

            imageView.snp.makeConstraints {
                $0.top.equalToSuperview()
                $0.leading.trailing.equalToSuperview()
                $0.centerX.equalToSuperview()
                $0.height.lessThanOrEqualToSuperview().multipliedBy(0.65)
            }

            pill.snp.makeConstraints {
                $0.top.equalTo(imageView.snp.bottom).offset(spaceL)
                $0.centerX.equalToSuperview()
            }

            titleLabel.snp.makeConstraints {
                $0.top.equalTo(pill.snp.bottom).offset(spaceM)
                $0.horizontalEdges.equalToSuperview().inset(spaceS)
            }

            subtitleLabel.snp.makeConstraints {
                $0.top.equalTo(titleLabel.snp.bottom).offset(spaceS)
                $0.horizontalEdges.equalToSuperview().inset(spaceL)
                $0.bottom.equalToSuperview()
            }

            pagesStackView.addArrangedSubview(pageView)

            pageView.snp.makeConstraints {
                $0.width.equalTo(imageScrollView.frameLayoutGuide)
                $0.height.equalTo(imageScrollView.frameLayoutGuide)
            }

            pageViews.append(pageView)
            
            imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
            pill.setContentCompressionResistancePriority(.required, for: .vertical)
            titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
            subtitleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        }
    }

    func clamp(page: Int) -> Int {
        guard !pages.isEmpty else {
            return .zero
        }

        return min(max(.zero, page), pages.count - 1)
    }
}
