import UIKit
import SnapKit

final class ExpenseAIEntryNoExpenseAlertView: UIView, LayoutScaleProviding {
    private let cardView = UIView()
    private let iconBackgroundView = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = Label()
    private let messageLabel = Label()
    private let buttonsStackView = UIStackView()
    private let addManuallyButton = Button()
    private let fixPromptButton = Button()

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
        titleLabel.apply(viewModel.title)
        messageLabel.apply(viewModel.message)
        addManuallyButton.apply(viewModel.addManuallyButton)
        fixPromptButton.apply(viewModel.fixPromptButton)
    }
}

private extension ExpenseAIEntryNoExpenseAlertView {
    func setupViews() {
        backgroundColor = UIColor.black.withAlphaComponent(0.35)

        cardView.backgroundColor = Asset.Colors.backgroundPrimary.color
        cardView.layer.cornerRadius = sizeXL

        iconBackgroundView.backgroundColor = Asset.Colors.errorColor.color.withAlphaComponent(0.12)
        iconBackgroundView.layer.cornerRadius = sizeL

        iconImageView.image = Asset.Icons.alertWraning.image
        iconImageView.contentMode = .scaleAspectFit

        buttonsStackView.axis = .vertical
        buttonsStackView.spacing = spaceS
    }

    func setupLayout() {
        addSubview(cardView)
        cardView.addSubview(iconBackgroundView)
        iconBackgroundView.addSubview(iconImageView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(messageLabel)
        cardView.addSubview(buttonsStackView)

        buttonsStackView.addArrangedSubview(addManuallyButton)
        buttonsStackView.addArrangedSubview(fixPromptButton)

        cardView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.horizontalEdges.equalToSuperview().inset(spaceL)
        }

        iconBackgroundView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(spaceL)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(sizeXL)
        }

        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(sizeM)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconBackgroundView.snp.bottom).offset(spaceM)
            make.horizontalEdges.equalToSuperview().inset(spaceL)
        }

        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(spaceS)
            make.horizontalEdges.equalToSuperview().inset(spaceL)
        }

        buttonsStackView.snp.makeConstraints { make in
            make.top.equalTo(messageLabel.snp.bottom).offset(spaceL)
            make.horizontalEdges.equalToSuperview().inset(spaceL)
            make.bottom.equalToSuperview().inset(spaceL)
        }
    }
}

extension ExpenseAIEntryNoExpenseAlertView {
    struct ViewModel: Equatable {
        let title: Label.LabelViewModel
        let message: Label.LabelViewModel
        let addManuallyButton: Button.ButtonViewModel
        let fixPromptButton: Button.ButtonViewModel

        init(
            title: Label.LabelViewModel = .init(),
            message: Label.LabelViewModel = .init(),
            addManuallyButton: Button.ButtonViewModel = .init(),
            fixPromptButton: Button.ButtonViewModel = .init()
        ) {
            self.title = title
            self.message = message
            self.addManuallyButton = addManuallyButton
            self.fixPromptButton = fixPromptButton
        }
    }
}
