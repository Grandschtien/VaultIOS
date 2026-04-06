import UIKit
import SnapKit

final class CategoryEditorView: UIView, LayoutScaleProviding {
    private var viewModel: CategoryEditorViewModel = .init()

    private let headerView = CategoryEditorHeaderView()
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let previewView = CategoryEditorPreviewView()
    private let nameField = TextField()
    private let emojiTitleLabel = Label()
    private let emojiGridView = CategoryEditorOptionsGridView()
    private let colorTitleLabel = Label()
    private let colorGridView = CategoryEditorOptionsGridView()
    private let loadingView = UIActivityIndicatorView(style: .medium)
    private let errorView = FullScreenCommonErrorView()
    private let actionStack = UIStackView()
    private let primaryButton = Button()
    private let deleteButton = Button()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with viewModel: CategoryEditorViewModel) {
        self.viewModel = viewModel

        headerView.configure(with: viewModel.header)
        primaryButton.apply(viewModel.primaryButton)

        if let deleteButtonViewModel = viewModel.deleteButton {
            deleteButton.isHidden = false
            deleteButton.apply(deleteButtonViewModel)
        } else {
            deleteButton.isHidden = true
        }

        switch viewModel.state {
        case .loading:
            scrollView.isHidden = true
            errorView.isHidden = true
            loadingView.isHidden = false
            loadingView.startAnimating()
        case let .error(errorViewModel):
            scrollView.isHidden = true
            errorView.isHidden = false
            loadingView.isHidden = true
            loadingView.stopAnimating()
            errorView.apply(errorViewModel)
        case let .loaded(content):
            scrollView.isHidden = false
            errorView.isHidden = true
            loadingView.isHidden = true
            loadingView.stopAnimating()
            previewView.configure(with: content.preview)
            nameField.apply(content.nameField)
            emojiTitleLabel.apply(content.emojiTitle)
            emojiGridView.configure(with: content.emojiItems)
            colorTitleLabel.apply(content.colorTitle)
            colorGridView.configure(with: content.colorItems)
        }
    }
}

private extension CategoryEditorView {
    func setupViews() {
        backgroundColor = Asset.Colors.backgroundPrimary.color

        scrollView.showsVerticalScrollIndicator = false
        contentStack.axis = .vertical
        contentStack.spacing = spaceS

        loadingView.hidesWhenStopped = true
        loadingView.color = Asset.Colors.interactiveElemetsPrimary.color
        errorView.isHidden = true
        deleteButton.isHidden = true
        actionStack.axis = .vertical
        actionStack.spacing = spaceXS
    }

    func setupLayout() {
        addSubview(headerView)
        addSubview(scrollView)
        addSubview(errorView)
        addSubview(loadingView)
        addSubview(actionStack)

        scrollView.addSubview(contentStack)

        [
            previewView,
            nameField,
            emojiTitleLabel,
            emojiGridView,
            colorTitleLabel,
            colorGridView
        ].forEach { contentStack.addArrangedSubview($0) }

        actionStack.addArrangedSubview(primaryButton)
        actionStack.addArrangedSubview(deleteButton)

        headerView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide)
            make.horizontalEdges.equalToSuperview()
        }

        actionStack.snp.makeConstraints { make in
            make.horizontalEdges.equalTo(safeAreaLayoutGuide).inset(spaceS)
            make.bottom.equalTo(safeAreaLayoutGuide).inset(spaceS)
        }

        scrollView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(spaceS)
            make.horizontalEdges.equalTo(safeAreaLayoutGuide).inset(spaceS)
            make.bottom.equalTo(actionStack.snp.top).offset(-spaceS)
        }

        contentStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView.snp.width)
        }

        errorView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(spaceS)
            make.horizontalEdges.equalTo(safeAreaLayoutGuide).inset(spaceS)
            make.bottom.equalTo(actionStack.snp.top).offset(-spaceS)
        }

        loadingView.snp.makeConstraints { make in
            make.center.equalTo(errorView)
        }
    }
}
