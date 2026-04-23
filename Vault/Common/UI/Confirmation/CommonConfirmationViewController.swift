import UIKit

final class CommonConfirmationViewController: UIViewController, HasContentView {
    typealias ContentView = CommonConfirmationView

    private let viewModel: CommonConfirmationView.ViewModel

    init(viewModel: CommonConfirmationView.ViewModel) {
        self.viewModel = viewModel
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

        contentView.configure(with: viewModel)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updatePreferredContentSizeToFitContent()
    }
}

private extension CommonConfirmationViewController {
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
