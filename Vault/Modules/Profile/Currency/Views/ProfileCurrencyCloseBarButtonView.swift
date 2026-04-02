import UIKit
import SnapKit

final class ProfileCurrencyCloseBarButtonView: UIView, LayoutScaleProviding {
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

    func configure(with viewModel: ProfileCurrencyViewModel.CloseButtonViewModel) {
        tapCommand = viewModel.tapCommand
    }
}

private extension ProfileCurrencyCloseBarButtonView {
    func setupViews() {
        backgroundColor = .clear
        button.tintColor = Asset.Colors.textAndIconPrimary.color
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
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
