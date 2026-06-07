import UIKit
import SnapKit

final class CommonConfirmationView: UIView, LayoutScaleProviding, ImageProviding {
    private let titleLabel = Label()
    private let subtitleLabel = Label()
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
        if let subtitle = viewModel.subtitle {
            subtitleLabel.apply(subtitle)
        }
        subtitleLabel.isHidden = viewModel.subtitle == nil
        confirmButton.apply(viewModel.confirmButton)
        cancelButton.apply(viewModel.cancelButton)
        closeCommand = viewModel.closeCommand
        closeButton.isEnabled = viewModel.isCloseEnabled
        closeButton.alpha = viewModel.isCloseEnabled ? 1 : 0.4
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
        addSubview(subtitleLabel)
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
            make.centerX.equalToSuperview()
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(spaceXS)
            make.horizontalEdges.equalToSuperview().inset(spaceS)
        }

        buttonStackView.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(spaceL)
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
        let subtitle: Label.LabelViewModel?
        let confirmButton: Button.ButtonViewModel
        let cancelButton: Button.ButtonViewModel
        let closeCommand: Command
        let isCloseEnabled: Bool

        init(
            title: Label.LabelViewModel = .init(),
            subtitle: Label.LabelViewModel? = nil,
            confirmButton: Button.ButtonViewModel = .init(),
            cancelButton: Button.ButtonViewModel = .init(),
            closeCommand: Command = .nope,
            isCloseEnabled: Bool = true
        ) {
            self.title = title
            self.subtitle = subtitle
            self.confirmButton = confirmButton
            self.cancelButton = cancelButton
            self.closeCommand = closeCommand
            self.isCloseEnabled = isCloseEnabled
        }
    }
}
