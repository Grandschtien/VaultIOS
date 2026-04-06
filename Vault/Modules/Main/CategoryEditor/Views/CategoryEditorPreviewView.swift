import UIKit
import SnapKit

final class CategoryEditorPreviewView: UIView, LayoutScaleProviding {
    private let circleView = UIView()
    private let emojiLabel = Label()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with viewModel: CategoryEditorViewModel.PreviewViewModel) {
        circleView.backgroundColor = viewModel.backgroundColor
        emojiLabel.apply(
            .init(
                text: viewModel.emojiText,
                font: Typography.typographyBold30,
                textColor: Asset.Colors.textAndIconPrimary.color,
                alignment: .center
            )
        )
    }
}

private extension CategoryEditorPreviewView {
    func setupViews() {
        backgroundColor = .clear

        circleView.layer.cornerRadius = sizeXL
        circleView.layer.borderWidth = 4
        circleView.layer.borderColor = UIColor.white.cgColor
        circleView.layer.shadowColor = UIColor.black.cgColor
        circleView.layer.shadowOpacity = 0.08
        circleView.layer.shadowOffset = CGSize(width: .zero, height: spaceXS)
        circleView.layer.shadowRadius = spaceS
    }

    func setupLayout() {
        addSubview(circleView)
        circleView.addSubview(emojiLabel)

        circleView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(sizeXXL)
        }

        emojiLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        snp.makeConstraints { make in
            make.height.equalTo(sizeXXL)
        }
    }
}
