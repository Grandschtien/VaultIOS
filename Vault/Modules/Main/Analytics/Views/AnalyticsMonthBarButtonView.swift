import UIKit
import SnapKit

final class AnalyticsMonthBarButtonView: UIView, LayoutScaleProviding, ImageProviding {
    private let button = UIButton(type: .system)
    private var tapCommand: Command = .nope
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
        button.configuration?.title = viewModel.title
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

        var configuration = UIButton.Configuration.plain()
        configuration.baseForegroundColor = Asset.Colors.textAndIconPrimary.color
        configuration.titleLineBreakMode = .byTruncatingTail
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = Typography.typographyMedium16
            return attributes
        }
        configuration.image = chevronDownImage
        configuration.imagePlacement = .trailing
        configuration.imagePadding = spaceXS
        configuration.imageColorTransformer = UIConfigurationColorTransformer { _ in
            Asset.Colors.textAndIconSecondary.color
        }
        configuration.contentInsets = NSDirectionalEdgeInsets(
            top: spaceXS,
            leading: spaceS,
            bottom: spaceXS,
            trailing: spaceS
        )
        button.configuration = configuration
        button.accessibilityIdentifier = AccessibilityIdentifier.Analytics.periodButton
        button.addTarget(self, action: #selector(handleTap), for: .touchUpInside)

        self.backgroundColor = Asset.Colors.interactiveInputBackground.color
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
