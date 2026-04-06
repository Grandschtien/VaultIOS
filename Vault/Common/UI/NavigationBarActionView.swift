import UIKit
import SnapKit

final class NavigationBarActionView: UIView, LayoutScaleProviding, ImageProviding {
    private let button = UIButton(type: .system)
    private var tapCommand: Command = .nope

    override var intrinsicContentSize: CGSize {
        CGSize(width: sizeM, height: sizeM)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with viewModel: ViewModel) {
        tapCommand = viewModel.tapCommand
        button.tintColor = viewModel.tintColor
        button.setTitle(nil, for: .normal)
        button.setImage(nil, for: .normal)
        button.titleLabel?.font = Typography.typographySemibold16
        button.isEnabled = viewModel.isEnabled
        button.alpha = viewModel.isEnabled ? 1 : 0.5

        switch viewModel.content {
        case .plus:
            button.setImage(plusImage(pointSize: sizeS, weight: .semibold), for: .normal)
        case let .text(title):
            button.setTitle(title, for: .normal)
        }
    }
}

private extension NavigationBarActionView {
    func setupViews() {
        backgroundColor = .clear
        button.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }

    func setupLayout() {
        addSubview(button)

        button.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    @objc
    func handleTap() {
        tapCommand.execute()
    }
}

extension NavigationBarActionView {
    struct ViewModel: Equatable {
        enum Content: Equatable {
            case plus
            case text(String)
        }

        let content: Content
        let tintColor: UIColor
        let isEnabled: Bool
        let tapCommand: Command

        init(
            content: Content = .plus,
            tintColor: UIColor = Asset.Colors.interactiveElemetsPrimary.color,
            isEnabled: Bool = true,
            tapCommand: Command = .nope
        ) {
            self.content = content
            self.tintColor = tintColor
            self.isEnabled = isEnabled
            self.tapCommand = tapCommand
        }
    }
}
