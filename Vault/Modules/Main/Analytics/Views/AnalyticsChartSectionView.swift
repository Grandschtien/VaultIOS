import UIKit
import SnapKit
import DGCharts

final class AnalyticsChartSectionView: UIView, LayoutScaleProviding, ImageProviding {
    private let chartView = PieChartView()
    private let centerContainer = UIView()
    private let centerIconView = UIImageView()
    private let centerTitleLabel = Label()
    private let centerValueLabel = Label()
    private let legendStackView = UIStackView()

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
        centerTitleLabel.apply(viewModel.centerTitle)
        centerValueLabel.apply(viewModel.centerValue)
        configureLegend(with: viewModel.legendItems)
        configureChart(with: viewModel.slices)
    }
}

private extension AnalyticsChartSectionView {
    func setupViews() {
        backgroundColor = .clear

        chartView.backgroundColor = .clear
        chartView.drawHoleEnabled = true
        chartView.holeRadiusPercent = 0.72
        chartView.transparentCircleRadiusPercent = 0.75
        chartView.rotationEnabled = false
        chartView.highlightPerTapEnabled = false
        chartView.drawEntryLabelsEnabled = false
        chartView.legend.enabled = false
        chartView.isUserInteractionEnabled = false
        chartView.usePercentValuesEnabled = false
        chartView.holeColor = Asset.Colors.backgroundPrimary.color

        centerContainer.backgroundColor = .clear

        centerIconView.image = sparklesImage
        centerIconView.tintColor = Asset.Colors.interactiveElemetsPrimary.color
        centerIconView.contentMode = .scaleAspectFit

        legendStackView.axis = .horizontal
        legendStackView.alignment = .center
        legendStackView.distribution = .fillEqually
        legendStackView.spacing = spaceS
    }

    func setupLayout() {
        addSubview(chartView)
        addSubview(centerContainer)
        addSubview(legendStackView)

        [centerIconView, centerTitleLabel, centerValueLabel].forEach {
            centerContainer.addSubview($0)
        }

        chartView.snp.makeConstraints { make in
            make.top.horizontalEdges.equalToSuperview()
            make.height.equalTo(chartView.snp.width)
        }

        centerContainer.snp.makeConstraints { make in
            make.center.equalTo(chartView)
            make.width.height.equalTo(sizeXXL)
        }

        centerIconView.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.width.height.equalTo(sizeS)
        }

        centerTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(centerIconView.snp.bottom).offset(spaceXS)
            make.horizontalEdges.equalToSuperview()
        }

        centerValueLabel.snp.makeConstraints { make in
            make.top.equalTo(centerTitleLabel.snp.bottom).offset(spaceXXS)
            make.horizontalEdges.equalToSuperview()
        }

        legendStackView.snp.makeConstraints { make in
            make.top.equalTo(chartView.snp.bottom).offset(spaceS)
            make.horizontalEdges.bottom.equalToSuperview()
        }
    }

    func configureChart(with slices: [ViewModel.Slice]) {
        guard slices.isEmpty == false else {
            chartView.clear()
            return
        }

        let entries = slices.enumerated().map { index, slice in
            PieChartDataEntry(value: slice.value, label: "slice-\(index)")
        }
        let dataSet = PieChartDataSet(entries: entries, label: "")
        dataSet.colors = slices.map(\.color)
        dataSet.sliceSpace = 6
        dataSet.selectionShift = .zero
        dataSet.drawValuesEnabled = false

        let data = PieChartData(dataSet: dataSet)
        data.setDrawValues(false)
        chartView.data = data
        data.notifyDataChanged()
        chartView.notifyDataSetChanged()
        chartView.setNeedsDisplay()
    }

    func configureLegend(with items: [ViewModel.LegendItem]) {
        legendStackView.arrangedSubviews.forEach { view in
            legendStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        items.forEach { item in
            legendStackView.addArrangedSubview(makeLegendItemView(for: item))
        }
    }

    func makeLegendItemView(for item: ViewModel.LegendItem) -> UIView {
        let container = UIStackView()
        container.axis = .horizontal
        container.alignment = .center
        container.spacing = spaceXS

        let dotView = UIView()
        dotView.backgroundColor = item.color
        dotView.layer.cornerRadius = spaceXS

        let label = Label()
        label.apply(
            .init(
                text: item.title,
                font: Typography.typographyMedium14,
                textColor: Asset.Colors.textAndIconSecondary.color,
                alignment: .left
            )
        )

        container.addArrangedSubview(dotView)
        container.addArrangedSubview(label)

        dotView.snp.makeConstraints { make in
            make.width.height.equalTo(sizeXS)
        }

        return container
    }
}

extension AnalyticsChartSectionView {
    struct ViewModel: Equatable {
        struct Slice: Equatable {
            let value: Double
            let color: UIColor
        }

        struct LegendItem: Equatable {
            let title: String
            let color: UIColor
        }

        let slices: [Slice]
        let legendItems: [LegendItem]
        let centerTitle: Label.LabelViewModel
        let centerValue: Label.LabelViewModel

        init(
            slices: [Slice] = [],
            legendItems: [LegendItem] = [],
            centerTitle: Label.LabelViewModel = .init(),
            centerValue: Label.LabelViewModel = .init()
        ) {
            self.slices = slices
            self.legendItems = legendItems
            self.centerTitle = centerTitle
            self.centerValue = centerValue
        }
    }
}
