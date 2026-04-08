import UIKit
import SnapKit

final class CategoryPeriodPickerView: UIView, LayoutScaleProviding {
    private var viewModel: CategoryPeriodPickerViewModel = .init()
    private var isApplyingViewModel = false
    private let fieldsStackView = UIStackView()
    private let fromFieldView = CategoryPeriodPickerFieldView()
    private let toFieldView = CategoryPeriodPickerFieldView()
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
        fromFieldView.configure(with: viewModel.fromField)
        toFieldView.configure(with: viewModel.toField)
        calendarView.availableDateRange = DateInterval(
            start: viewModel.calendar.minimumDate,
            end: viewModel.calendar.maximumDate
        )
        isApplyingViewModel = true
        calendarView.visibleDateComponents = Calendar.current.dateComponents(
            [.year, .month, .day],
            from: viewModel.calendar.visibleMonthDate
        )
        selectionBehavior.selectedDate = Calendar.current.dateComponents(
            [.year, .month, .day],
            from: viewModel.calendar.selectedDate
        )
        isApplyingViewModel = false
    }
}

private extension CategoryPeriodPickerView {
    func setupViews() {
        backgroundColor = Asset.Colors.backgroundPrimary.color

        fieldsStackView.axis = .vertical
        fieldsStackView.spacing = spaceS

        calendarView.selectionBehavior = selectionBehavior
        calendarView.locale = Locale.current
        calendarView.tintColor = Asset.Colors.interactiveElemetsPrimary.color
    }

    func setupLayout() {
        addSubview(fieldsStackView)
        addSubview(calendarView)

        [fromFieldView, toFieldView].forEach { fieldsStackView.addArrangedSubview($0) }

        fieldsStackView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide).offset(spaceS)
            make.horizontalEdges.equalTo(safeAreaLayoutGuide).inset(spaceS)
        }

        calendarView.snp.makeConstraints { make in
            make.top.equalTo(fieldsStackView.snp.bottom).offset(spaceS)
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
        guard !isApplyingViewModel else {
            return
        }

        guard let date = dateComponents.flatMap(Calendar.current.date(from:)) else {
            return
        }

        viewModel.calendar.selectionCommand.execute(date)
    }
}
