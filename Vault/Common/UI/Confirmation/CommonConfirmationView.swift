import UIKit
import SnapKit

final class CommonConfirmationView: UIView, LayoutScaleProviding, ImageProviding {
    private let titleLabel = Label()
    private let closeButton = UIButton(type: .system)
    private let confirmButton = Button()
    private let cancelButton = Button()
    private let buttonStackView = UIStackView()

    private var closeCommand: Command = .nope

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
        titleLabel.apply(viewModel.title)
        confirmButton.apply(viewModel.confirmButton)
        cancelButton.apply(viewModel.cancelButton)
        closeCommand = viewModel.closeCommand
    }
}

private extension CommonConfirmationView {
    func setupViews() {
        backgroundColor = Asset.Colors.backgroundPrimary.color

        closeButton.tintColor = Asset.Colors.textAndIconPrimary.color
        closeButton.setImage(xmarkImage, for: .normal)
        closeButton.addTarget(self, action: #selector(handleTapClose), for: .touchUpInside)

        buttonStackView.axis = .vertical
        buttonStackView.spacing = spaceS
    }

    func setupLayout() {
        addSubview(titleLabel)
        addSubview(closeButton)
        addSubview(buttonStackView)

        buttonStackView.addArrangedSubview(confirmButton)
        buttonStackView.addArrangedSubview(cancelButton)

        closeButton.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide).inset(spaceS)
            make.trailing.equalTo(safeAreaLayoutGuide).inset(spaceS)
            make.size.equalTo(sizeM)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide).inset(spaceS)
            make.leading.equalTo(safeAreaLayoutGuide).inset(spaceS)
            make.trailing.equalTo(safeAreaLayoutGuide).inset(spaceXL)
        }

        buttonStackView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(spaceL)
            make.horizontalEdges.equalTo(safeAreaLayoutGuide).inset(spaceS)
            make.bottom.equalTo(safeAreaLayoutGuide).inset(spaceS)
        }
    }

    @objc
    func handleTapClose() {
        executeAfterDismissingKeyboard(closeCommand)
    }
}

extension CommonConfirmationView {
    struct ViewModel: Equatable {
        let title: Label.LabelViewModel
        let confirmButton: Button.ButtonViewModel
        let cancelButton: Button.ButtonViewModel
        let closeCommand: Command

        init(
            title: Label.LabelViewModel = .init(),
            confirmButton: Button.ButtonViewModel = .init(),
            cancelButton: Button.ButtonViewModel = .init(),
            closeCommand: Command = .nope
        ) {
            self.title = title
            self.confirmButton = confirmButton
            self.cancelButton = cancelButton
            self.closeCommand = closeCommand
        }
    }
}
