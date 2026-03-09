//
//  PageControl.swift
//  Vault
//
//  Created by Codex on 09.03.2026.
//

import UIKit

final class PageControl: UIView {
    private let stackView = UIStackView()
    private(set) var viewModel: PageControlViewModel

    private var indicatorButtons: [UIButton] = []
    private var indicatorWidthConstraints: [NSLayoutConstraint] = []

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

    func apply(_ viewModel: PageControlViewModel, animated: Bool = true) {
        self.viewModel = viewModel.normalized()

        if indicatorButtons.count != self.viewModel.pageCount {
            rebuildIndicators()
        }

        let applyStateChanges = { [self] in
            for index in indicatorButtons.indices {
                let isActive = index == self.viewModel.currentPage
                indicatorWidthConstraints[index].constant = isActive ? self.viewModel.activeWidth : self.viewModel.indicatorSize
                indicatorButtons[index].backgroundColor = isActive ? self.viewModel.activeColor : self.viewModel.inactiveColor
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
        stackView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func rebuildIndicators() {
        indicatorButtons.forEach { button in
            stackView.removeArrangedSubview(button)
            button.removeFromSuperview()
        }
        indicatorButtons.removeAll()
        indicatorWidthConstraints.removeAll()

        stackView.spacing = viewModel.spacing

        for index in 0..<viewModel.pageCount {
            let button = UIButton(type: .custom)
            button.tag = index
            button.translatesAutoresizingMaskIntoConstraints = false
            button.layer.cornerRadius = viewModel.indicatorSize / 2
            button.clipsToBounds = true
            button.addTarget(self, action: #selector(handleIndicatorTap(_:)), for: .touchUpInside)

            stackView.addArrangedSubview(button)

            let widthConstraint = button.widthAnchor.constraint(equalToConstant: viewModel.indicatorSize)
            NSLayoutConstraint.activate([
                widthConstraint,
                button.heightAnchor.constraint(equalToConstant: viewModel.indicatorSize)
            ])

            indicatorButtons.append(button)
            indicatorWidthConstraints.append(widthConstraint)
        }
    }

    @objc
    private func handleIndicatorTap(_ sender: UIButton) {
        guard viewModel.allowsSelection else { return }
        onPageSelected?(sender.tag)
    }
}

extension PageControl {
    struct PageControlViewModel {
        let pageCount: Int
        let currentPage: Int
        let activeColor: UIColor
        let inactiveColor: UIColor
        let indicatorSize: CGFloat
        let activeWidth: CGFloat
        let spacing: CGFloat
        let allowsSelection: Bool
        let animationDuration: TimeInterval

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
    }
}
