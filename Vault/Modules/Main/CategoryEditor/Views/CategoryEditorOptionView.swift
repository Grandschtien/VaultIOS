import UIKit
import SnapKit

final class CategoryEditorOptionView: UIControl, LayoutScaleProviding {
    private var tapCommand: Command = .nope

    private let circleView = UIView()
    private let emojiLabel = Label()
    private let symbolImageView = UIImageView()

    override var intrinsicContentSize: CGSize {
        CGSize(width: sizeXL, height: sizeXL)
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
        circleView.backgroundColor = viewModel.backgroundColor
        circleView.layer.borderColor = viewModel.borderColor.cgColor
        circleView.layer.borderWidth = viewModel.borderWidth
        emojiLabel.isHidden = true
        symbolImageView.isHidden = true

        switch viewModel.content {
        case .none:
            break
        case let .emoji(value):
            emojiLabel.isHidden = false
            emojiLabel.apply(
                .init(
                    text: value,
                    font: Typography.typographyBold20,
                    textColor: viewModel.foregroundColor,
                    alignment: .center
                )
            )
        case let .symbol(name):
            symbolImageView.isHidden = false
            symbolImageView.image = UIImage(systemName: name)
            symbolImageView.tintColor = viewModel.foregroundColor
        }
    }
}

private extension CategoryEditorOptionView {
    func setupViews() {
        backgroundColor = .clear
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)

        circleView.isUserInteractionEnabled = false
        emojiLabel.isUserInteractionEnabled = false
        symbolImageView.isUserInteractionEnabled = false
        circleView.layer.cornerRadius = sizeL
        circleView.layer.borderWidth = 2
        symbolImageView.contentMode = .scaleAspectFit
    }

    func setupLayout() {
        addSubview(circleView)
        circleView.addSubview(emojiLabel)
        circleView.addSubview(symbolImageView)

        circleView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(sizeXL)
        }

        emojiLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        symbolImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(sizeM)
        }
    }

    @objc
    func handleTap() {
        tapCommand.execute()
    }
}

extension CategoryEditorOptionView {
    struct ViewModel: Equatable {
        enum Content: Equatable {
            case none
            case emoji(String)
            case symbol(String)
        }

        let content: Content
        let backgroundColor: UIColor
        let foregroundColor: UIColor
        let borderColor: UIColor
        let borderWidth: CGFloat
        let tapCommand: Command

        init(
            content: Content = .symbol("plus"),
            backgroundColor: UIColor = Asset.Colors.interactiveInputBackground.color,
            foregroundColor: UIColor = Asset.Colors.textAndIconSecondary.color,
            borderColor: UIColor = .clear,
            borderWidth: CGFloat = .zero,
            tapCommand: Command = .nope
        ) {
            self.content = content
            self.backgroundColor = backgroundColor
            self.foregroundColor = foregroundColor
            self.borderColor = borderColor
            self.borderWidth = borderWidth
            self.tapCommand = tapCommand
        }
    }
}

final class CategoryEditorOptionsGridView: UIView, LayoutScaleProviding {
    private let containerView = UIView()
    private let firstRowStack = UIStackView()
    private let secondRowStack = UIStackView()
    private lazy var optionViews = (0..<8).map { _ in CategoryEditorOptionView() }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with items: [CategoryEditorOptionView.ViewModel]) {
        for (index, optionView) in optionViews.enumerated() {
            guard items.indices.contains(index) else {
                optionView.isHidden = true
                continue
            }

            optionView.isHidden = false
            optionView.configure(with: items[index])
        }
    }
}

private extension CategoryEditorOptionsGridView {
    func setupViews() {
        backgroundColor = .clear

        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = sizeL
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.05
        containerView.layer.shadowOffset = CGSize(width: .zero, height: spaceXS)
        containerView.layer.shadowRadius = spaceS

        [firstRowStack, secondRowStack].forEach {
            $0.axis = .horizontal
            $0.alignment = .fill
            $0.distribution = .fillEqually
            $0.spacing = spaceS
        }
    }

    func setupLayout() {
        addSubview(containerView)
        containerView.addSubview(firstRowStack)
        containerView.addSubview(secondRowStack)

        optionViews.prefix(4).forEach { firstRowStack.addArrangedSubview($0) }
        optionViews.suffix(4).forEach { secondRowStack.addArrangedSubview($0) }

        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        firstRowStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(spaceS)
            make.horizontalEdges.equalToSuperview().inset(spaceS)
        }

        secondRowStack.snp.makeConstraints { make in
            make.top.equalTo(firstRowStack.snp.bottom).offset(spaceS)
            make.horizontalEdges.equalToSuperview().inset(spaceS)
            make.bottom.equalToSuperview().inset(spaceS)
        }
    }
}
