// Created by Egor Shkarin on 25.03.2026

import UIKit
import SnapKit

final class MainBlockingErrorView: UIView, LayoutScaleProviding {
    private let stackView = UIStackView()
    private let titleLabel = Label()
    private let subtitleLabel = Label()
    private let retryButton = Button()

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

extension MainBlockingErrorView {
    func configure(with viewModel: ViewModel) {
        titleLabel.apply(viewModel.title)
        subtitleLabel.apply(viewModel.subtitle)
        retryButton.apply(viewModel.retryButton)
    }
}

private extension MainBlockingErrorView {
    func setupViews() {
        backgroundColor = Asset.Colors.backgroundPrimary.color

        stackView.axis = .vertical
        stackView.spacing = spaceS
        stackView.alignment = .fill

        subtitleLabel.numberOfLines = 0
    }

    func setupLayout() {
        addSubview(stackView)
        [titleLabel, subtitleLabel, retryButton].forEach {
            stackView.addArrangedSubview($0)
        }

        stackView.snp.makeConstraints { make in
            make.centerY.equalTo(safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview().inset(spaceL)
        }
    }
}

extension MainBlockingErrorView {
    struct ViewModel: Equatable {
        let title: Label.LabelViewModel
        let subtitle: Label.LabelViewModel
        let retryButton: Button.ButtonViewModel

        init(
            title: Label.LabelViewModel = .init(),
            subtitle: Label.LabelViewModel = .init(),
            retryButton: Button.ButtonViewModel = .init()
        ) {
            self.title = title
            self.subtitle = subtitle
            self.retryButton = retryButton
        }
    }
}
