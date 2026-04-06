import UIKit
import SnapKit

final class CategoryPeriodPickerView: UIView, LayoutScaleProviding {
    private var viewModel: CategoryPeriodPickerViewModel = .init()
    private var isApplyingSelection = false
    private let calendarView = UICalendarView()
    private lazy var selectionBehavior = UICalendarSelectionSingleDate(delegate: self)

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        setupViews()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with viewModel: CategoryPeriodPickerViewModel) {
        self.viewModel = viewModel
        calendarView.availableDateRange = DateInterval(
            start: viewModel.calendar.minimumDate,
            end: viewModel.calendar.maximumDate
        )
        isApplyingSelection = true
        selectionBehavior.selectedDate = Calendar.current.dateComponents(
            [.year, .month, .day],
            from: viewModel.calendar.selectedDate
        )
        isApplyingSelection = false
    }
}

private extension CategoryPeriodPickerView {
    func setupViews() {
        backgroundColor = Asset.Colors.backgroundPrimary.color
        calendarView.selectionBehavior = selectionBehavior
        calendarView.locale = Locale.current
        calendarView.tintColor = Asset.Colors.interactiveElemetsPrimary.color
    }

    func setupLayout() {
        addSubview(calendarView)

        calendarView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide).offset(spaceS)
            make.horizontalEdges.equalTo(safeAreaLayoutGuide).inset(spaceS)
            make.bottom.lessThanOrEqualTo(safeAreaLayoutGuide).inset(spaceS)
        }
    }
}

extension CategoryPeriodPickerView: UICalendarSelectionSingleDateDelegate {
    func dateSelection(
        _ selection: UICalendarSelectionSingleDate,
        didSelectDate dateComponents: DateComponents?
    ) {
        guard !isApplyingSelection else {
            return
        }

        guard let date = dateComponents.flatMap(Calendar.current.date(from:)) else {
            return
        }

        viewModel.calendar.selectionCommand.execute(date)
    }
}
