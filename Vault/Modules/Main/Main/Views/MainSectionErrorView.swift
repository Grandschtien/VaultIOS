// Created by Egor Shkarin 23.03.2026

import UIKit
import SnapKit

final class MainSectionErrorView: UIControl, LayoutScaleProviding {
    private(set) var viewModel: ViewModel = .init()

    private let titleLabel = Label()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(_ viewModel: ViewModel) {
        self.viewModel = viewModel
        titleLabel.apply(viewModel.title)
    }
}

private extension MainSectionErrorView {
    func setupViews() {
        backgroundColor = Asset.Colors.interactiveInputBackground.color
        layer.cornerRadius = sizeM
        layer.borderWidth = 1
        layer.borderColor = Asset.Colors.textAndIconPlaceseholder.color.withAlphaComponent(0.35).cgColor
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }

    func setupLayout() {
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(spaceS)
        }

        snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(sizeXL)
        }
    }

    @objc
    func handleTap() {
        viewModel.tapCommand.execute()
    }
}

extension MainSectionErrorView {
    struct ViewModel: Equatable {
        let title: Label.LabelViewModel
        let tapCommand: Command

        init(
            title: Label.LabelViewModel = .init(),
            tapCommand: Command = .nope
        ) {
            self.title = title
            self.tapCommand = tapCommand
        }
    }
}
