// Created by Egor Shkarin on 27.03.2026

import Foundation

protocol CategoriesListBusinessLogic: Sendable {
    func fetchData() async
}

protocol CategoriesListHandler: AnyObject, Sendable {
    func handleTapRetry() async
    func handleTapCategory(id: String, name: String) async
    func handleTapAddCategory() async
}

actor CategoriesListInteractor: CategoriesListBusinessLogic {
    private let presenter: CategoriesListPresentationLogic
    private let router: CategoriesListRoutingLogic
    private let repository: MainFlowDomainRepositoryProtocol
    private let observer: MainFlowDomainObserverProtocol

    private var loadingState: LoadingStatus = .idle
    private var categories: [MainCategoryCardModel] = []
    private var observationTask: Task<Void, Never>?

    init(
        presenter: CategoriesListPresentationLogic,
        router: CategoriesListRoutingLogic,
        repository: MainFlowDomainRepositoryProtocol,
        observer: MainFlowDomainObserverProtocol
    ) {
        self.presenter = presenter
        self.router = router
        self.repository = repository
        self.observer = observer
    }

    deinit {
        observationTask?.cancel()
    }

    func fetchData() async {
        startObservingIfNeeded()

        loadingState = .loading
        categories = []
        await presentFetchedData()

        do {
            try await repository.refreshCategories()
            categories = observer.currentCategoriesSnapshot().categories
            loadingState = .loaded
            await presentFetchedData()
        } catch {
            if categories.isEmpty {
                loadingState = .failed(.undelinedError(description: error.localizedDescription))
                await presentFetchedData()
            }
        }
    }
}

private extension CategoriesListInteractor {
    func startObservingIfNeeded() {
        guard observationTask == nil else {
            return
        }

        let stream = observer.subscribeCategories()
        observationTask = Task { [weak self] in
            for await snapshot in stream {
                guard let self else {
                    return
                }

                await self.handleSnapshot(snapshot)
            }
        }
    }

    func handleSnapshot(_ snapshot: MainFlowCategoriesSnapshot) async {
        categories = snapshot.categories

        switch loadingState {
        case .loaded:
            await presentFetchedData()
        case .loading where !categories.isEmpty:
            loadingState = .loaded
            await presentFetchedData()
        default:
            break
        }
    }

    func presentFetchedData() async {
        await presenter.presentFetchedData(
            CategoriesListFetchData(
                loadingState: loadingState,
                categories: categories
            )
        )
    }
}

extension CategoriesListInteractor: CategoriesListHandler {
    func handleTapRetry() async {
        await fetchData()
    }

    func handleTapCategory(id: String, name: String) async {
        await router.openCategory(id: id, name: name)
    }

    func handleTapAddCategory() async {
        await router.openCategoryCreate()
    }
}
