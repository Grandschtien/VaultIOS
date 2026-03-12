//
//  PageControl.swift
//  Vault
//
//  Created by Egor Shkarin on 09.03.2026.
//

import UIKit
import SnapKit

final class PageControl: UIView {
    private let stackView = UIStackView()
    private(set) var viewModel: PageControlViewModel

    private var indicatorButtons: [UIButton] = []
    private var indicatorWidthConstraints: [Constraint] = []
    private var indicatorHeightConstraints: [Constraint] = []

    private weak var connectedScrollView: UIScrollView?
    private var contentOffsetObservation: NSKeyValueObservation?
    private var boundsObservation: NSKeyValueObservation?

    var onPageSelected: ((Int) -> Void)?

    init(viewModel: PageControlViewModel) {
        self.viewModel = viewModel.normalized()
        super.init(frame: .zero)
        setupLayout()
        apply(self.viewModel, animated: false)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        disconnectScrollView()
    }

    func connect(to scrollView: UIScrollView) {
        disconnectScrollView()
        connectedScrollView = scrollView

        contentOffsetObservation = scrollView.observe(\.contentOffset, options: [.initial, .new]) { [weak self] scrollView, _ in
            self?.update(using: scrollView)
        }

        boundsObservation = scrollView.observe(\.bounds, options: [.new]) { [weak self] scrollView, _ in
            self?.update(using: scrollView)
        }
    }

    func disconnectScrollView() {
        contentOffsetObservation?.invalidate()
        boundsObservation?.invalidate()
        contentOffsetObservation = nil
        boundsObservation = nil
        connectedScrollView = nil
    }

    func update(using scrollView: UIScrollView) {
        guard viewModel.pageCount > 0 else { return }

        let pageWidth = max(scrollView.bounds.width, 1)
        let rawProgress = scrollView.contentOffset.x / pageWidth
        let maxProgress = CGFloat(max(0, viewModel.pageCount - 1))
        let clampedProgress = min(max(0, rawProgress), maxProgress)
        applyScrollProgress(clampedProgress)
    }

    func apply(_ viewModel: PageControlViewModel, animated: Bool = true) {
        self.viewModel = viewModel.normalized()

        if indicatorButtons.count != self.viewModel.pageCount {
            rebuildIndicators()
        }

        stackView.spacing = self.viewModel.spacing
        let activePage = self.viewModel.currentPage

        let applyStateChanges = { [weak self] in
            guard let self else { return }

            for index in indicatorButtons.indices {
                let isActive = index == activePage
                let targetWidth = isActive ? self.viewModel.activeWidth : self.viewModel.indicatorSize

                indicatorWidthConstraints[index].update(offset: targetWidth)
                indicatorHeightConstraints[index].update(offset: self.viewModel.indicatorSize)

                indicatorButtons[index].backgroundColor = isActive ? self.viewModel.activeColor : self.viewModel.inactiveColor
                indicatorButtons[index].layer.cornerRadius = self.viewModel.indicatorSize / 2
                indicatorButtons[index].isUserInteractionEnabled = self.viewModel.allowsSelection
                indicatorButtons[index].accessibilityTraits = isActive ? [.button, .selected] : .button
            }

            layoutIfNeeded()
        }

        if animated {
            UIView.animate(
                withDuration: self.viewModel.animationDuration,
                delay: 0,
                options: [.curveEaseInOut, .allowUserInteraction],
                animations: applyStateChanges
            )
        } else {
            applyStateChanges()
        }
    }

    private func setupLayout() {
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill

        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func rebuildIndicators() {
        indicatorButtons.forEach { button in
            stackView.removeArrangedSubview(button)
            button.removeFromSuperview()
        }
        indicatorButtons.removeAll()
        indicatorWidthConstraints.removeAll()
        indicatorHeightConstraints.removeAll()

        stackView.spacing = viewModel.spacing

        for index in 0..<viewModel.pageCount {
            let button = UIButton(type: .custom)
            button.tag = index
            button.layer.cornerRadius = viewModel.indicatorSize / 2
            button.clipsToBounds = true
            button.addTarget(self, action: #selector(handleIndicatorTap(_:)), for: .touchUpInside)

            stackView.addArrangedSubview(button)

            var widthConstraint: Constraint?
            var heightConstraint: Constraint?
            button.snp.makeConstraints { make in
                widthConstraint = make.width.equalTo(viewModel.indicatorSize).constraint
                heightConstraint = make.height.equalTo(viewModel.indicatorSize).constraint
            }

            guard let widthConstraint, let heightConstraint else { continue }

            indicatorButtons.append(button)
            indicatorWidthConstraints.append(widthConstraint)
            indicatorHeightConstraints.append(heightConstraint)
        }
    }

    private func applyScrollProgress(_ progress: CGFloat) {
        guard !indicatorButtons.isEmpty else { return }

        let fromPage = Int(floor(progress))
        let toPage = min(fromPage + 1, viewModel.pageCount - 1)
        let transition = progress - CGFloat(fromPage)
        let selectedPage = Int(round(progress))
        viewModel = viewModel.withCurrentPage(selectedPage)

        for index in indicatorButtons.indices {
            var width = viewModel.indicatorSize
            var color = viewModel.inactiveColor

            if fromPage == toPage, index == fromPage {
                width = viewModel.activeWidth
                color = viewModel.activeColor
            } else if index == fromPage {
                width = interpolate(viewModel.activeWidth, viewModel.indicatorSize, transition)
                color = viewModel.activeColor.blended(with: viewModel.inactiveColor, fraction: transition)
            } else if index == toPage {
                width = interpolate(viewModel.indicatorSize, viewModel.activeWidth, transition)
                color = viewModel.inactiveColor.blended(with: viewModel.activeColor, fraction: transition)
            }

            indicatorWidthConstraints[index].update(offset: width)
            indicatorHeightConstraints[index].update(offset: viewModel.indicatorSize)
            indicatorButtons[index].backgroundColor = color
            indicatorButtons[index].layer.cornerRadius = viewModel.indicatorSize / 2
            indicatorButtons[index].accessibilityTraits = index == selectedPage ? [.button, .selected] : .button
        }

        layoutIfNeeded()
    }

    private func interpolate(_ from: CGFloat, _ to: CGFloat, _ fraction: CGFloat) -> CGFloat {
        from + (to - from) * fraction
    }

    @objc
    private func handleIndicatorTap(_ sender: UIButton) {
        guard viewModel.allowsSelection else { return }

        if let connectedScrollView {
            let pageWidth = max(connectedScrollView.bounds.width, 1)
            let targetOffset = CGPoint(
                x: CGFloat(sender.tag) * pageWidth,
                y: connectedScrollView.contentOffset.y
            )
            connectedScrollView.setContentOffset(targetOffset, animated: true)
        }

        onPageSelected?(sender.tag)
    }
}

extension PageControl {
    struct PageControlViewModel: Equatable {
        let pageCount: Int
        let currentPage: Int
        let activeColor: UIColor
        let inactiveColor: UIColor
        let indicatorSize: CGFloat
        let activeWidth: CGFloat
        let spacing: CGFloat
        let allowsSelection: Bool
        let animationDuration: TimeInterval
        
        static let initial = PageControlViewModel(
            pageCount: .zero,
            currentPage: .zero,
            activeColor: Asset.Colors.interactiveElemetsPrimary.color,
            inactiveColor: Asset.Colors.textAndIconPlaceseholder.color,
            indicatorSize: 8,
            activeWidth: 24,
            spacing: 8,
            allowsSelection: true
        )

        init(
            pageCount: Int,
            currentPage: Int,
            activeColor: UIColor,
            inactiveColor: UIColor,
            indicatorSize: CGFloat = 12,
            activeWidth: CGFloat = 36,
            spacing: CGFloat = 8,
            allowsSelection: Bool = true,
            animationDuration: TimeInterval = 0.22
        ) {
            self.pageCount = pageCount
            self.currentPage = currentPage
            self.activeColor = activeColor
            self.inactiveColor = inactiveColor
            self.indicatorSize = indicatorSize
            self.activeWidth = activeWidth
            self.spacing = spacing
            self.allowsSelection = allowsSelection
            self.animationDuration = animationDuration
        }

        fileprivate func normalized() -> PageControlViewModel {
            let safePageCount = max(0, pageCount)
            let safeCurrentPage = min(max(0, currentPage), max(0, safePageCount - 1))
            let safeIndicatorSize = max(1, indicatorSize)
            let safeActiveWidth = max(safeIndicatorSize, activeWidth)

            return PageControlViewModel(
                pageCount: safePageCount,
                currentPage: safeCurrentPage,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                indicatorSize: safeIndicatorSize,
                activeWidth: safeActiveWidth,
                spacing: max(0, spacing),
                allowsSelection: allowsSelection,
                animationDuration: max(0, animationDuration)
            )
        }

        fileprivate func withCurrentPage(_ currentPage: Int) -> PageControlViewModel {
            PageControlViewModel(
                pageCount: pageCount,
                currentPage: currentPage,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                indicatorSize: indicatorSize,
                activeWidth: activeWidth,
                spacing: spacing,
                allowsSelection: allowsSelection,
                animationDuration: animationDuration
            ).normalized()
        }
    }
}

private extension UIColor {
    func blended(with color: UIColor, fraction: CGFloat) -> UIColor {
        let fraction = min(max(0, fraction), 1)
        let start = rgbaComponents
        let end = color.rgbaComponents

        return UIColor(
            red: start.red + (end.red - start.red) * fraction,
            green: start.green + (end.green - start.green) * fraction,
            blue: start.blue + (end.blue - start.blue) * fraction,
            alpha: start.alpha + (end.alpha - start.alpha) * fraction
        )
    }

    var rgbaComponents: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        if getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return (red, green, blue, alpha)
        }

        let ciColor = CIColor(color: self)
        return (ciColor.red, ciColor.green, ciColor.blue, ciColor.alpha)
    }
}
