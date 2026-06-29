import UIKit
import SnapKit

final class AnalyticsMonthBarButtonView: UIView, LayoutScaleProviding, ImageProviding {
    private let button = UIButton(type: .system)
    private var tapCommand: Command = .nope
    private let chevronImageView = UIImageView()
    private var currentViewModel = ViewModel()
    private var preferredSize: CGSize = .zero

    override var intrinsicContentSize: CGSize {
        preferredSize == .zero ? measuredSize() : preferredSize
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        preferredSize == .zero ? measuredSize() : preferredSize
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

    func configure(
        with viewModel: ViewModel,
        animated: Bool = false
    ) {
        let shouldAnimate = animated
            && currentViewModel.title != viewModel.title
            && currentViewModel.title.isEmpty == false

        tapCommand = viewModel.tapCommand
        button.setTitle(viewModel.title, for: .normal)
        let targetSize = measuredSize()
        currentViewModel = viewModel

        guard shouldAnimate else {
            applyPreferredSize(targetSize)
            return
        }

        UIView.animate(
            withDuration: 0.25,
            delay: .zero,
            options: [.curveEaseInOut, .allowUserInteraction]
        ) {
            self.applyPreferredSize(targetSize)
            self.superview?.layoutIfNeeded()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = self.frame.height / 2
    }
}

private extension AnalyticsMonthBarButtonView {
    func setupViews() {
        backgroundColor = .clear

        button.configuration = .plain()
        button.setTitleColor(Asset.Colors.textAndIconPrimary.color, for: .normal)
        button.titleLabel?.font = Typography.typographyMedium16
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        button.titleLabel?.numberOfLines = 1
        button.configuration?.contentInsets = NSDirectionalEdgeInsets(
            top: spaceXS,
            leading: spaceS,
            bottom: spaceXS,
            trailing: sizeL
        )
        button.addTarget(self, action: #selector(handleTap), for: .touchUpInside)

        chevronImageView.image = chevronDownImage
        chevronImageView.tintColor = Asset.Colors.textAndIconSecondary.color
        chevronImageView.contentMode = .scaleAspectFit
        
        self.backgroundColor = Asset.Colors.interactiveInputBackground.color
    }

    func setupLayout() {
        addSubview(button)
        addSubview(chevronImageView)

        button.snp.makeConstraints { make in
            make.leading.verticalEdges.equalToSuperview().inset(spaceXS)
        }

        chevronImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(spaceS)
            make.leading.equalTo(button.snp.trailing).inset(spaceS)
        }
    }

    @objc
    func handleTap() {
        tapCommand.execute()
    }

    func measuredSize() -> CGSize {
        button.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    }

    func applyPreferredSize(_ size: CGSize) {
        preferredSize = size
        bounds.size = size
        frame.size = size
        invalidateIntrinsicContentSize()
        setNeedsLayout()
        layoutIfNeeded()
    }
}

extension AnalyticsMonthBarButtonView {
    struct ViewModel: Equatable {
        let title: String
        let tapCommand: Command

        init(
            title: String = "",
            tapCommand: Command = .nope
        ) {
            self.title = title
            self.tapCommand = tapCommand
        }
    }
}
