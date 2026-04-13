import UIKit
import SnapKit

final class ExpenseAIEntryVoiceButtonView: UIView, LayoutScaleProviding {
    private enum Constants {
        static let animationDuration: TimeInterval = 0.2
    }

    private(set) var viewModel: ViewModel = .init()

    private let button = UIButton(type: .custom)
    private let contentStackView = UIStackView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()

    override var intrinsicContentSize: CGSize {
        CGSize(
            width: viewModel.isRecording ? sizeXXL : sizeXL,
            height: sizeXL
        )
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

    func apply(_ viewModel: ViewModel) {
        let shouldAnimate = self.viewModel.isRecording != viewModel.isRecording && window != nil
        self.viewModel = viewModel

        button.isEnabled = viewModel.isEnabled
        button.alpha = viewModel.isEnabled ? 1 : 0.6
        button.backgroundColor = viewModel.isRecording
            ? Asset.Colors.interactiveElemetsPrimary.color
            : Asset.Colors.interactiveInputBackground.color

        iconImageView.image = viewModel.icon
        iconImageView.tintColor = viewModel.isRecording
            ? Asset.Colors.textAndIconPrimaryInverted.color
            : Asset.Colors.interactiveElemetsPrimary.color

        titleLabel.text = viewModel.title
        titleLabel.textColor = viewModel.isRecording
            ? Asset.Colors.textAndIconPrimaryInverted.color
            : Asset.Colors.interactiveElemetsPrimary.color
        titleLabel.isHidden = !viewModel.isRecording || viewModel.title.isEmpty

        invalidateIntrinsicContentSize()

        guard shouldAnimate else {
            superview?.layoutIfNeeded()
            return
        }

        UIView.animate(withDuration: Constants.animationDuration) {
            self.superview?.layoutIfNeeded()
        }
    }
}

private extension ExpenseAIEntryVoiceButtonView {
    func setupViews() {
        self.isUserInteractionEnabled = true
        backgroundColor = .clear

        button.layer.cornerRadius = sizeM
        button.layer.cornerCurve = .continuous
        button.directionalLayoutMargins = .init(
            top: spaceS,
            leading: spaceS,
            bottom: spaceS,
            trailing: spaceS
        )

        contentStackView.axis = .horizontal
        contentStackView.alignment = .center
        contentStackView.spacing = spaceXS
        contentStackView.isUserInteractionEnabled = false

        iconImageView.contentMode = .scaleAspectFit

        titleLabel.font = Typography.typographySemibold16
        titleLabel.textAlignment = .left
        titleLabel.isHidden = true
        titleLabel.isUserInteractionEnabled = false
        iconImageView.isUserInteractionEnabled = false

        button.addTarget(self, action: #selector(handleTouchDown), for: .touchDown)
        button.addTarget(self, action: #selector(handleTouchUp), for: .touchUpInside)
        button.addTarget(self, action: #selector(handleTouchUp), for: .touchUpOutside)
        button.addTarget(self, action: #selector(handleTouchUp), for: .touchCancel)
    }

    func setupLayout() {
        addSubview(button)
        button.addSubview(contentStackView)

        contentStackView.addArrangedSubview(iconImageView)
        contentStackView.addArrangedSubview(titleLabel)

        button.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentStackView.snp.makeConstraints { make in
            make.verticalEdges.equalTo(button.layoutMarginsGuide)
            make.horizontalEdges.equalTo(button.layoutMarginsGuide)
            make.center.equalToSuperview()
        }

        iconImageView.snp.makeConstraints { make in
            make.size.equalTo(sizeM)
        }
    }

    @objc
    func handleTouchDown() {
        guard viewModel.isEnabled else {
            return
        }

        viewModel.startRecordingCommand.execute()
    }

    @objc
    func handleTouchUp() {
        guard viewModel.isEnabled else {
            return
        }

        viewModel.stopRecordingCommand.execute()
    }
}

extension ExpenseAIEntryVoiceButtonView {
    struct ViewModel: Equatable {
        let title: String
        let icon: UIImage?
        let isRecording: Bool
        let isEnabled: Bool
        let startRecordingCommand: Command
        let stopRecordingCommand: Command

        init(
            title: String = "",
            icon: UIImage? = nil,
            isRecording: Bool = false,
            isEnabled: Bool = true,
            startRecordingCommand: Command = .nope,
            stopRecordingCommand: Command = .nope
        ) {
            self.title = title
            self.icon = icon
            self.isRecording = isRecording
            self.isEnabled = isEnabled
            self.startRecordingCommand = startRecordingCommand
            self.stopRecordingCommand = stopRecordingCommand
        }
    }
}
