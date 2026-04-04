import UIKit
import SnapKit

final class AddExpenseSheetHeaderView: UIView, LayoutScaleProviding {
    private(set) var viewModel: ViewModel = .init()

    private let handleView = UIView()
    private let titleLabel = Label()
    private let closeButton = UIButton(type: .system)

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

private extension AddExpenseSheetHeaderView {
    func setupViews() {
        backgroundColor = .clear

        handleView.backgroundColor = Asset.Colors.textAndIconPlaceseholder.color.withAlphaComponent(0.4)
        handleView.layer.cornerRadius = spaceXXS

        closeButton.tintColor = Asset.Colors.textAndIconSecondary.color
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.addTarget(self, action: #selector(handleTapClose), for: .touchUpInside)
    }

    func setupLayout() {
        addSubview(handleView)
        addSubview(titleLabel)
        addSubview(closeButton)

        handleView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(spaceXS)
            make.centerX.equalToSuperview()
            make.width.equalTo(sizeM)
            make.height.equalTo(spaceXXS)
        }

        closeButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(spaceS)
            make.width.height.equalTo(sizeM)
            make.centerY.equalTo(titleLabel)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(handleView.snp.bottom).offset(spaceS)
            make.leading.equalToSuperview().offset(spaceXL)
            make.trailing.equalToSuperview().inset(spaceXL)
            make.bottom.equalToSuperview()
        }
    }

    @objc
    func handleTapClose() {
        viewModel.closeCommand.execute()
    }
}

extension AddExpenseSheetHeaderView {
    struct ViewModel: Equatable {
        let title: Label.LabelViewModel
        let closeCommand: Command

        init(
            title: Label.LabelViewModel = .init(),
            closeCommand: Command = .nope
        ) {
            self.title = title
            self.closeCommand = closeCommand
        }
    }
}
