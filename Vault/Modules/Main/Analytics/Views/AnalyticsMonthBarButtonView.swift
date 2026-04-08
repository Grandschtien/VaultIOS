import UIKit
import SnapKit

final class AnalyticsMonthBarButtonView: UIView, LayoutScaleProviding {
    private let button = UIButton(type: .system)
    private var tapCommand: Command = .nope
    private let chevronImageView = UIImageView(image: UIImage(systemName: "chevron.down"))

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

    func configure(with viewModel: ViewModel) {
        tapCommand = viewModel.tapCommand
        button.setTitle(viewModel.title, for: .normal)
        invalidateIntrinsicContentSize()
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
        button.configuration?.contentInsets = NSDirectionalEdgeInsets(
            top: spaceXS,
            leading: spaceS,
            bottom: spaceXS,
            trailing: sizeL
        )
        button.addTarget(self, action: #selector(handleTap), for: .touchUpInside)

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
