import UIKit
import SnapKit

final class CategoryEditorView: UIView, LayoutScaleProviding {
    private var viewModel: CategoryEditorViewModel = .init()
    private var lastCustomEmojiFocusID: UUID?

    private lazy var dismissKeyboardTapGestureRecognizer = UITapGestureRecognizer(
        target: self,
        action: #selector(handleTapBackground)
    )
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
    private let customEmojiTextField = EmojiKeyboardTextField()

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
            dismissCustomEmojiKeyboard()
            scrollView.isHidden = true
            errorView.isHidden = true
            loadingView.isHidden = false
            loadingView.startAnimating()
        case let .error(errorViewModel):
            dismissCustomEmojiKeyboard()
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
            requestCustomEmojiKeyboardIfNeeded(focusID: content.customEmojiFocusID)
        }
    }
}

private extension CategoryEditorView {
    func setupViews() {
        backgroundColor = Asset.Colors.backgroundPrimary.color
        dismissKeyboardTapGestureRecognizer.cancelsTouchesInView = false
        dismissKeyboardTapGestureRecognizer.delegate = self
        addGestureRecognizer(dismissKeyboardTapGestureRecognizer)

        scrollView.showsVerticalScrollIndicator = false
        contentStack.axis = .vertical
        contentStack.spacing = spaceS

        loadingView.hidesWhenStopped = true
        loadingView.color = Asset.Colors.interactiveElemetsPrimary.color
        errorView.isHidden = true
        deleteButton.isHidden = true
        actionStack.axis = .vertical
        actionStack.spacing = spaceXS

        customEmojiTextField.delegate = self
        customEmojiTextField.tintColor = .clear
        customEmojiTextField.textColor = .clear
        customEmojiTextField.backgroundColor = .clear
        customEmojiTextField.autocorrectionType = .no
        customEmojiTextField.spellCheckingType = .no
        customEmojiTextField.smartInsertDeleteType = .no
        customEmojiTextField.smartQuotesType = .no
        customEmojiTextField.smartDashesType = .no
    }

    func setupLayout() {
        addSubview(headerView)
        addSubview(scrollView)
        addSubview(errorView)
        addSubview(loadingView)
        addSubview(actionStack)
        addSubview(customEmojiTextField)

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

        customEmojiTextField.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
            make.width.height.equalTo(0)
        }
    }

    func requestCustomEmojiKeyboardIfNeeded(focusID: UUID?) {
        guard let focusID,
              focusID != lastCustomEmojiFocusID
        else {
            return
        }

        lastCustomEmojiFocusID = focusID
        customEmojiTextField.text = nil
        customEmojiTextField.becomeFirstResponder()
    }

    func dismissCustomEmojiKeyboard() {
        customEmojiTextField.resignFirstResponder()
    }

    @objc
    func handleTapBackground() {
        endEditing(true)
    }
}

extension CategoryEditorView: UITextFieldDelegate {
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        guard case let .loaded(content) = viewModel.state,
              let emoji = string.firstEmojiCluster else {
            return false
        }

        customEmojiTextField.text = nil
        customEmojiTextField.resignFirstResponder()
        content.onCustomEmojiSelected.execute(emoji)

        return false
    }
}

extension CategoryEditorView: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
    ) -> Bool {
        guard let touchedView = touch.view else {
            return true
        }

        return !touchedView.hasSuperview(of: UIControl.self)
            && !touchedView.hasSuperview(of: UITextView.self)
            && !touchedView.hasSuperview(of: UITableViewCell.self)
            && !touchedView.hasSuperview(of: UICollectionViewCell.self)
    }
}

private extension UIView {
    func hasSuperview<T: UIView>(of type: T.Type) -> Bool {
        sequence(first: self, next: { $0.superview }).contains { $0 is T }
    }
}

private final class EmojiKeyboardTextField: UITextField {
    override var textInputMode: UITextInputMode? {
        UITextInputMode.activeInputModes.first { $0.primaryLanguage == "emoji" } ?? super.textInputMode
    }
}

private extension String {
    var firstEmojiCluster: String? {
        first(where: \.isEmojiCluster).map(String.init)
    }
}

private extension Character {
    var isEmojiCluster: Bool {
        unicodeScalars.contains { scalar in
            scalar.properties.isEmojiPresentation || scalar.properties.isEmoji
        }
    }
}
