import Foundation

protocol ExpenseCategoryPickerBusinessLogic: Sendable {
    func fetchData() async
}

protocol ExpenseCategoryPickerOutput: AnyObject, Sendable {
    func handleDidSelectCategory(_ category: ExpenseCategorySelectionModel) async
}

protocol ExpenseCategoryPickerHandler: AnyObject, Sendable {
    func handleTapCategory(id: String) async
    func handleTapAdd() async
    func handleTapRetry() async
    func handleTapClose() async
}

actor ExpenseCategoryPickerInteractor: ExpenseCategoryPickerBusinessLogic {
    private let presenter: ExpenseCategoryPickerPresentationLogic
    private let router: ExpenseCategoryPickerRoutingLogic
    private let repository: MainFlowDomainRepositoryProtocol
    private let observer: MainFlowDomainObserverProtocol
    private let output: ExpenseCategoryPickerOutput

    private var loadingState: LoadingStatus = .idle
    private var categories: [ExpenseCategorySelectionModel] = []
    private var selectedCategoryID: String?

    init(
        presenter: ExpenseCategoryPickerPresentationLogic,
        router: ExpenseCategoryPickerRoutingLogic,
        repository: MainFlowDomainRepositoryProtocol,
        observer: MainFlowDomainObserverProtocol,
        output: ExpenseCategoryPickerOutput,
        selectedCategoryID: String?
    ) {
        self.presenter = presenter
        self.router = router
        self.repository = repository
        self.observer = observer
        self.output = output
        self.selectedCategoryID = selectedCategoryID
    }

    func fetchData() async {
        loadingState = .loading
        categories = makeSelectionModels(from: observer.currentCategoriesSnapshot().categories)
        normalizeSelection()
        await presentFetchedData()

        do {
            try await repository.refreshCategories()
            categories = makeSelectionModels(from: observer.currentCategoriesSnapshot().categories)
            loadingState = .loaded
        } catch {
            categories = makeSelectionModels(from: observer.currentCategoriesSnapshot().categories)
            loadingState = categories.isEmpty
                ? .failed(.undelinedError(description: error.localizedDescription))
                : .loaded
        }

        normalizeSelection()
        await presentFetchedData()
    }
}

private extension ExpenseCategoryPickerInteractor {
    func presentFetchedData() async {
        await presenter.presentFetchedData(
            ExpenseCategoryPickerFetchData(
                loadingState: loadingState,
                categories: categories,
                selectedCategoryID: selectedCategoryID
            )
        )
    }

    func makeSelectionModels(from categories: [MainCategoryCardModel]) -> [ExpenseCategorySelectionModel] {
        categories.map {
            ExpenseCategorySelectionModel(
                id: $0.id,
                name: $0.name,
                icon: $0.icon,
                color: $0.color
            )
        }
    }

    func normalizeSelection() {
        guard let selectedCategoryID else {
            return
        }

        if !categories.contains(where: { $0.id == selectedCategoryID }) {
            self.selectedCategoryID = nil
        }
    }
}

extension ExpenseCategoryPickerInteractor: ExpenseCategoryPickerHandler {
    func handleTapCategory(id: String) async {
        guard categories.contains(where: { $0.id == id }) else {
            return
        }

        if selectedCategoryID == id {
            selectedCategoryID = nil
        } else {
            selectedCategoryID = id
        }

        await presentFetchedData()
    }

    func handleTapAdd() async {
        guard let selectedCategoryID,
              let category = categories.first(where: { $0.id == selectedCategoryID }) else {
            return
        }

        await output.handleDidSelectCategory(category)
        await router.close()
    }

    func handleTapRetry() async {
        await fetchData()
    }

    func handleTapClose() async {
        await router.close()
    }
}
