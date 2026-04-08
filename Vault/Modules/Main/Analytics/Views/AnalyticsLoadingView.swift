import UIKit
import SnapKit
import SkeletonView

final class AnalyticsLoadingView: UIView, LayoutScaleProviding {
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()
    private let periodPlaceholder = UIView()
    private let amountPlaceholder = UIView()
    private let chartPlaceholder = UIView()
    private let titlePlaceholder = UIView()
    private let rowPlaceholders = (0..<3).map { _ in UIView() }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func startAnimating() {
        [periodPlaceholder, amountPlaceholder, chartPlaceholder, titlePlaceholder]
            .forEach { $0.showAnimatedGradientSkeleton() }
        rowPlaceholders.forEach { $0.showAnimatedGradientSkeleton() }
    }

    func stopAnimating() {
        [periodPlaceholder, amountPlaceholder, chartPlaceholder, titlePlaceholder]
            .forEach { $0.hideSkeleton() }
        rowPlaceholders.forEach { $0.hideSkeleton() }
    }
}

private extension AnalyticsLoadingView {
    func setupViews() {
        backgroundColor = Asset.Colors.backgroundPrimary.color

        scrollView.showsVerticalScrollIndicator = false

        stackView.axis = .vertical
        stackView.spacing = spaceM

        [periodPlaceholder, amountPlaceholder, chartPlaceholder, titlePlaceholder]
            .forEach(configurePlaceholder)
        rowPlaceholders.forEach(configureCardPlaceholder)
    }

    func setupLayout() {
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)

        [
            periodPlaceholder,
            amountPlaceholder,
            chartPlaceholder,
            titlePlaceholder
        ].forEach { stackView.addArrangedSubview($0) }
        rowPlaceholders.forEach { stackView.addArrangedSubview($0) }

        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView.snp.width)
        }

        stackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(spaceS)
            make.horizontalEdges.equalToSuperview().inset(spaceS)
            make.bottom.equalToSuperview().inset(spaceS)
        }

        periodPlaceholder.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.height.equalTo(sizeS)
            make.width.equalTo(sizeXL)
        }

        amountPlaceholder.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.height.equalTo(sizeL)
            make.width.equalTo(sizeXXL)
        }

        chartPlaceholder.snp.makeConstraints { make in
            make.height.equalTo(chartPlaceholder.snp.width)
        }

        titlePlaceholder.snp.makeConstraints { make in
            make.height.equalTo(sizeM)
            make.width.equalTo(sizeXXL)
        }

        rowPlaceholders.forEach { placeholder in
            placeholder.snp.makeConstraints { make in
                make.height.equalTo(sizeXL)
            }
        }
    }

    func configurePlaceholder(_ view: UIView) {
        view.isSkeletonable = true
        view.backgroundColor = Asset.Colors.interactiveInputBackground.color
        view.layer.cornerRadius = sizeS
        view.skeletonCornerRadius = Float(sizeS)
    }

    func configureCardPlaceholder(_ view: UIView) {
        configurePlaceholder(view)
        view.layer.cornerRadius = sizeM
        view.skeletonCornerRadius = Float(sizeM)
    }
}
