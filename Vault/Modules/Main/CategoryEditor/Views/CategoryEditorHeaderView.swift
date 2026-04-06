import UIKit
import SnapKit

final class CategoryEditorHeaderView: UIView, LayoutScaleProviding, ImageProviding {
    private var tapCommand: Command = .nope

    private let backButton = UIButton(type: .system)
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

    func configure(with viewModel: ViewModel) {
        tapCommand = viewModel.backCommand
        titleLabel.apply(viewModel.title)
    }
}

private extension CategoryEditorHeaderView {
    func setupViews() {
        backgroundColor = .clear

        backButton.tintColor = Asset.Colors.interactiveElemetsPrimary.color
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.addTarget(self, action: #selector(handleTapBack), for: .touchUpInside)
    }

    func setupLayout() {
        addSubview(backButton)
        addSubview(titleLabel)

        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(spaceS)
            make.centerY.equalTo(titleLabel)
            make.width.height.equalTo(sizeM)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(spaceS)
            make.leading.equalToSuperview().offset(spaceXL)
            make.trailing.equalToSuperview().inset(spaceXL)
            make.bottom.equalToSuperview()
        }
    }

    @objc
    func handleTapBack() {
        tapCommand.execute()
    }
}

extension CategoryEditorHeaderView {
    struct ViewModel: Equatable {
        let title: Label.LabelViewModel
        let backCommand: Command

        init(
            title: Label.LabelViewModel = .init(),
            backCommand: Command = .nope
        ) {
            self.title = title
            self.backCommand = backCommand
        }
    }
}
