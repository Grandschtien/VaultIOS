import UIKit

final class CommonConfirmationViewController: UIViewController, HasContentView {
    typealias ContentView = CommonConfirmationView

    private let baseViewModel: CommonConfirmationView.ViewModel
    private var isConfirmLoading = false

    private lazy var confirmTapCommand = Command { [weak self] in
        await self?.handleTapConfirm()
    }

    init(viewModel: CommonConfirmationView.ViewModel) {
        self.baseViewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    override func loadView() {
        view = ContentView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        render()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updatePreferredContentSizeToFitContent()
    }
}

private extension CommonConfirmationViewController {
    func render() {
        contentView.configure(with: viewModel())
    }

    func viewModel() -> CommonConfirmationView.ViewModel {
        let confirmButton = baseViewModel.confirmButton
        let cancelButton = baseViewModel.cancelButton

        return CommonConfirmationView.ViewModel(
            title: baseViewModel.title,
            confirmButton: .init(
                title: confirmButton.title,
                titleColor: confirmButton.titleColor,
                backgroundColor: confirmButton.backgroundColor,
                font: confirmButton.font,
                isEnabled: confirmButton.isEnabled,
                isLoading: isConfirmLoading || confirmButton.isLoading,
                tapCommand: confirmTapCommand,
                leftIcon: confirmButton.leftIcon,
                rightIcon: confirmButton.rightIcon,
                iconTintColor: confirmButton.iconTintColor,
                height: confirmButton.height,
                cornerRadius: confirmButton.cornerRadius
            ),
            cancelButton: .init(
                title: cancelButton.title,
                titleColor: cancelButton.titleColor,
                backgroundColor: cancelButton.backgroundColor,
                font: cancelButton.font,
                isEnabled: cancelButton.isEnabled && !isConfirmLoading,
                isLoading: cancelButton.isLoading,
                tapCommand: cancelButton.tapCommand,
                leftIcon: cancelButton.leftIcon,
                rightIcon: cancelButton.rightIcon,
                iconTintColor: cancelButton.iconTintColor,
                height: cancelButton.height,
                cornerRadius: cancelButton.cornerRadius
            ),
            closeCommand: baseViewModel.closeCommand,
            isCloseEnabled: !isConfirmLoading
        )
    }

    func handleTapConfirm() async {
        guard !isConfirmLoading else {
            return
        }

        isConfirmLoading = true
        render()
        updatePreferredContentSizeToFitContent()

        await baseViewModel.confirmButton.tapCommand.executeAsync()

        isConfirmLoading = false

        guard isViewLoaded else {
            return
        }

        render()
        updatePreferredContentSizeToFitContent()
    }

    func updatePreferredContentSizeToFitContent() {
        let preferredWidth = view.bounds.width > .zero
            ? view.bounds.width
            : view.window?.bounds.width ?? UIScreen.main.bounds.width

        guard preferredWidth > .zero else {
            return
        }

        let preferredHeight = contentView.systemLayoutSizeFitting(
            CGSize(
                width: preferredWidth,
                height: UIView.layoutFittingCompressedSize.height
            ),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height

        guard preferredHeight > .zero else {
            return
        }

        let preferredContentSize = CGSize(
            width: preferredWidth,
            height: preferredHeight
        )

        if self.preferredContentSize != preferredContentSize {
            self.preferredContentSize = preferredContentSize
        }

        if navigationController?.preferredContentSize != preferredContentSize {
            navigationController?.preferredContentSize = preferredContentSize
        }

        sheetPresentationController?.invalidateDetents()
        navigationController?.sheetPresentationController?.invalidateDetents()
    }
}
