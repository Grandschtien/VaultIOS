import UIKit
import SnapKit

final class CategoryPeriodPickerFieldView: UIView, LayoutScaleProviding {
    private let containerView = UIView()
    private let titleLabel = Label()
    private let valueLabel = Label()
    private let labelsStackView = UIStackView()
    private var tapCommand: Command = .nope

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with viewModel: CategoryPeriodPickerViewModel.PeriodFieldViewModel) {
        tapCommand = viewModel.tapCommand
        titleLabel.apply(viewModel.title)
        valueLabel.apply(viewModel.value)
        containerView.layer.borderColor = borderColor(isActive: viewModel.isActive).cgColor
        containerView.backgroundColor = containerBackgroundColor(isActive: viewModel.isActive)
    }
}

private extension CategoryPeriodPickerFieldView {
    func setupViews() {
        backgroundColor = .clear

        containerView.layer.cornerRadius = sizeM
        containerView.layer.borderWidth = 1

        labelsStackView.axis = .vertical
        labelsStackView.spacing = spaceXXS

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        self.addGestureRecognizer(tapRecognizer)
    }

    func setupLayout() {
        addSubview(containerView)
        [titleLabel, valueLabel].forEach { labelsStackView.addArrangedSubview($0) }
        containerView.addSubview(labelsStackView)

        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        labelsStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(spaceS)
        }
    }

    func borderColor(isActive: Bool) -> UIColor {
        if isActive {
            return Asset.Colors.interactiveElemetsPrimary.color
        }

        return Asset.Colors.textAndIconPlaceseholder.color.withAlphaComponent(0.2)
    }

    func containerBackgroundColor(isActive: Bool) -> UIColor {
        if isActive {
            return Asset.Colors.interactiveInputBackground.color
        }

        return Asset.Colors.backgroundPrimary.color
    }

    @objc
    func handleTap() {
        tapCommand.execute()
    }
}
