import UIKit
import SnapKit

final class CategoryPeriodPickerConfirmBarButtonView: UIView {
    private let button = UIButton(type: .system)
    private var tapCommand: Command = .nope

    override var intrinsicContentSize: CGSize {
        button.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
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

    func configure(with viewModel: CategoryPeriodPickerViewModel.ConfirmButtonViewModel) {
        tapCommand = viewModel.tapCommand
        button.setTitle(viewModel.title, for: .normal)
        button.isEnabled = viewModel.isEnabled
        button.alpha = viewModel.isEnabled ? 1 : 0.5
        invalidateIntrinsicContentSize()
    }
}

private extension CategoryPeriodPickerConfirmBarButtonView {
    func setupViews() {
        backgroundColor = .clear
        button.setTitleColor(Asset.Colors.interactiveElemetsPrimary.color, for: .normal)
        button.titleLabel?.font = Typography.typographyMedium16
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
