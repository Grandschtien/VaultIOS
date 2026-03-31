// Created by Codex on 30.03.2026

import UIKit
import SnapKit

final class DeleteTableViewCellWrapper<
    WrappedView: UIView & ConfigurableCellWrappedView
>: BaseTableViewCellWrapper<WrappedView> {
    private let animationDuration: TimeInterval = 0.2

    private enum SwipeState {
        case closed
        case revealed
        case deleting
    }

    private let deleteView = UIView()
    private let deleteIconView = UIImageView()
    private let deleteTitleLabel = Label()
    private let deleteContentStack = UIStackView()

    private var wrappedViewLeadingConstraint: Constraint?
    private var wrappedViewTrailingConstraint: Constraint?
    private var panStartOffset: CGFloat = .zero

    private(set) var deleteViewModel: DeleteViewModel = .init()
    private(set) var currentRevealOffset: CGFloat = .zero

    private var swipeState: SwipeState = .closed

    override func prepareForReuse() {
        super.prepareForReuse()
        resetSwipeState(animated: false)
        deleteViewModel = .init()
    }

    func configure(with viewModel: ViewModel) {
        super.configure(with: viewModel.wrappedViewModel)
        applyDeleteViewModel(viewModel.deleteViewModel)
    }

    override func setupViews() {
        super.setupViews()
        contentView.clipsToBounds = true

        deleteView.backgroundColor = Asset.Colors.errorColor.color
        deleteView.layer.cornerRadius = spaceL

        deleteIconView.contentMode = .scaleAspectFit
        deleteIconView.tintColor = .white

        deleteContentStack.axis = .vertical
        deleteContentStack.alignment = .center

        let panGestureRecognizer = UIPanGestureRecognizer(
            target: self,
            action: #selector(handlePan(_:))
        )
        panGestureRecognizer.delegate = self
        wrappedView.addGestureRecognizer(panGestureRecognizer)

        let tapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(handleDeleteTap)
        )
        deleteView.addGestureRecognizer(tapGestureRecognizer)
    }

    override func setupLayout() {
        contentView.addSubview(deleteView)
        super.setupLayout()

        deleteView.addSubview(deleteContentStack)
        deleteContentStack.addArrangedSubview(deleteIconView)
        deleteContentStack.addArrangedSubview(deleteTitleLabel)

        deleteView.snp.makeConstraints { make in
            make.horizontalEdges.top.equalToSuperview().inset(2)
            make.bottom.equalToSuperview().inset(spaceXS)
        }

        deleteContentStack.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(spaceS)
        }

        deleteIconView.snp.makeConstraints { make in
            make.size.equalTo(sizeM)
        }
    }

    override func setupWrappedViewConstraints() {
        wrappedView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.height.equalTo(height)
            make.bottom.equalToSuperview().inset(spaceXS)
            wrappedViewLeadingConstraint = make.leading.equalToSuperview().constraint
            wrappedViewTrailingConstraint = make.trailing.equalToSuperview().constraint
        }
    }

    func triggerDeleteIfPossible() {
        guard deleteViewModel.state != .deleting else {
            return
        }

        swipeState = .deleting
        setRevealOffset(maxRevealOffset, animated: true)
        deleteViewModel.deleteCommand.execute()
    }

    @objc
    func handleDeleteTap() {
        triggerDeleteIfPossible()
    }

    @objc
    func handlePan(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard deleteViewModel.state != .deleting else {
            return
        }

        let translation = gestureRecognizer.translation(in: contentView)

        switch gestureRecognizer.state {
        case .began:
            panStartOffset = currentRevealOffset
        case .changed:
            let rawOffset = panStartOffset - translation.x
            setRevealOffset(rawOffset, animated: false)
        case .ended, .cancelled, .failed:
            settleSwipePosition()
        default:
            break
        }
    }

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer else {
            return true
        }

        let velocity = panGestureRecognizer.velocity(in: contentView)
        return abs(velocity.x) > abs(velocity.y)
    }
}

private extension DeleteTableViewCellWrapper {
    var maxRevealOffset: CGFloat {
        sizeXL + spaceS
    }

    var revealThreshold: CGFloat {
        sizeS
    }

    var fullSwipeThreshold: CGFloat {
        sizeXXL
    }

    func applyDeleteViewModel(_ viewModel: DeleteViewModel) {
        deleteViewModel = viewModel

        deleteTitleLabel.apply(viewModel.title)

        if let icon = viewModel.icon ?? trashImage {
            deleteIconView.image = icon.withRenderingMode(.alwaysTemplate)
            deleteIconView.isHidden = false
        } else {
            deleteIconView.image = nil
            deleteIconView.isHidden = true
        }
    }

    func resetSwipeState(animated: Bool) {
        swipeState = .closed
        setRevealOffset(.zero, animated: animated)
    }

    func setRevealOffset(_ offset: CGFloat, animated: Bool) {
        let boundedOffset = min(max(offset, .zero), maxRevealOffset)
        currentRevealOffset = boundedOffset

        let updateOffsets = {
            self.wrappedViewLeadingConstraint?.update(offset: -boundedOffset)
            self.wrappedViewTrailingConstraint?.update(offset: -boundedOffset)
            self.contentView.layoutIfNeeded()
        }

        if animated {
            UIView.animate(withDuration: animationDuration, animations: updateOffsets)
        } else {
            updateOffsets()
        }
    }

    func settleSwipePosition() {
        if currentRevealOffset >= fullSwipeThreshold {
            triggerDeleteIfPossible()
            return
        }

        if currentRevealOffset >= revealThreshold {
            swipeState = .revealed
            setRevealOffset(maxRevealOffset, animated: true)
        } else {
            resetSwipeState(animated: true)
        }
    }

}

// MARK: ViewModel

extension DeleteTableViewCellWrapper {
    struct DeleteViewModel: Equatable {
        enum State: Equatable {
            case idle
            case deleting
        }

        let id: String
        let title: Label.LabelViewModel
        let icon: UIImage?
        let state: State
        let deleteCommand: Command

        init(
            id: String = "",
            title: Label.LabelViewModel = .init(),
            icon: UIImage? = nil,
            state: State = .idle,
            deleteCommand: Command = .nope
        ) {
            self.id = id
            self.title = title
            self.icon = icon
            self.state = state
            self.deleteCommand = deleteCommand
        }
    }

    struct ViewModel {
        let wrappedViewModel: WrappedView.ViewModel
        let deleteViewModel: DeleteViewModel

        init(
            wrappedViewModel: WrappedView.ViewModel,
            deleteViewModel: DeleteViewModel = .init()
        ) {
            self.wrappedViewModel = wrappedViewModel
            self.deleteViewModel = deleteViewModel
        }
    }

}
