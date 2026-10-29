import XCTest
@testable import Vylok

@MainActor
final class ExpenseCategoryPickerInteractorTests: XCTestCase {
    func testFetchDataLoadsCategoriesAndKeepsCurrentSelection() async {
        let presenter = ExpenseCategoryPickerPresentationLogicMock()
        let router = ExpenseCategoryPickerRoutingLogicMock()
        let observer = MainFlowDomainObserverProtocolMock()
        observer.subscribeCategoriesReturnValue = AsyncStream { _ in }
        observer.currentCategoriesSnapshotReturnValue = .init()
        observer.currentCategoriesSnapshotReturnValue = .init(
            categories: [
                .init(id: "food", name: "Food", icon: "🍔", color: "green", amount: 12, currency: "USD"),
                .init(id: "car", name: "Car", icon: "🚗", color: "blue", amount: 9, currency: "USD")
            ]
        )
        let repository = MainFlowDomainRepositoryProtocolMock()
        let output = ExpenseCategoryPickerOutputMock()
        let sut = makeSut(
            presenter: presenter,
            router: router,
            repository: repository,
            observer: observer,
            output: output,
            selectedCategoryID: "car"
        )

        await sut.fetchData()

        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.categories.count, 2)
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.selectedCategoryID, "car")
    }

    func testHandleTapCategoryTogglesActiveSelection() async {
        let presenter = ExpenseCategoryPickerPresentationLogicMock()
        let router = ExpenseCategoryPickerRoutingLogicMock()
        let observer = MainFlowDomainObserverProtocolMock()
        observer.subscribeCategoriesReturnValue = AsyncStream { _ in }
        observer.currentCategoriesSnapshotReturnValue = .init()
        observer.currentCategoriesSnapshotReturnValue = .init(
            categories: [
                .init(id: "food", name: "Food", icon: "🍔", color: "green", amount: 12, currency: "USD")
            ]
        )
        let repository = MainFlowDomainRepositoryProtocolMock()
        let output = ExpenseCategoryPickerOutputMock()
        let sut = makeSut(
            presenter: presenter,
            router: router,
            repository: repository,
            observer: observer,
            output: output,
            selectedCategoryID: nil
        )

        await sut.fetchData()
        await sut.handleTapCategory(id: "food")
        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.selectedCategoryID, "food")

        await sut.handleTapCategory(id: "food")
        XCTAssertNil(presenter.presentFetchedDataReceivedInvocations.last?.selectedCategoryID)
    }

    func testHandleTapAddNotifiesOutputAndClosesPicker() async {
        let presenter = ExpenseCategoryPickerPresentationLogicMock()
        let router = ExpenseCategoryPickerRoutingLogicMock()
        let observer = MainFlowDomainObserverProtocolMock()
        observer.subscribeCategoriesReturnValue = AsyncStream { _ in }
        observer.currentCategoriesSnapshotReturnValue = .init()
        observer.currentCategoriesSnapshotReturnValue = .init(
            categories: [
                .init(id: "food", name: "Food", icon: "🍔", color: "green", amount: 12, currency: "USD")
            ]
        )
        let repository = MainFlowDomainRepositoryProtocolMock()
        let output = ExpenseCategoryPickerOutputMock()
        let sut = makeSut(
            presenter: presenter,
            router: router,
            repository: repository,
            observer: observer,
            output: output,
            selectedCategoryID: "food"
        )

        await sut.fetchData()
        await sut.handleTapAdd()

        XCTAssertEqual(output.handleDidSelectCategoryReceivedInvocations.last?.id, "food")
        XCTAssertEqual(router.closeCallsCount, 1)
    }

    func testFetchDataShowsFailureWhenRefreshFailsAndNoCachedCategories() async {
        let presenter = ExpenseCategoryPickerPresentationLogicMock()
        let router = ExpenseCategoryPickerRoutingLogicMock()
        let observer = MainFlowDomainObserverProtocolMock()
        observer.subscribeCategoriesReturnValue = AsyncStream { _ in }
        observer.currentCategoriesSnapshotReturnValue = .init()
        let repository = MainFlowDomainRepositoryProtocolMock()
        repository.refreshCategoriesThrowableError = TestError.any
        let output = ExpenseCategoryPickerOutputMock()
        let sut = makeSut(
            presenter: presenter,
            router: router,
            repository: repository,
            observer: observer,
            output: output,
            selectedCategoryID: nil
        )

        await sut.fetchData()

        guard let last = presenter.presentFetchedDataReceivedInvocations.last else {
            return XCTFail("Expected presenter updates")
        }

        if case .failed = last.loadingState {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected failed loading state")
        }
    }

    func testHandleTapCreateCategoryOpensCreateFlow() async {
        let presenter = ExpenseCategoryPickerPresentationLogicMock()
        let router = ExpenseCategoryPickerRoutingLogicMock()
        let observer = MainFlowDomainObserverProtocolMock()
        observer.subscribeCategoriesReturnValue = AsyncStream { _ in }
        observer.currentCategoriesSnapshotReturnValue = .init()
        observer.currentCategoriesSnapshotReturnValue = .init(
            categories: [
                .init(id: "food", name: "Food", icon: "🍔", color: "green", amount: 12, currency: "USD")
            ]
        )
        let repository = MainFlowDomainRepositoryProtocolMock()
        let output = ExpenseCategoryPickerOutputMock()
        let sut = makeSut(
            presenter: presenter,
            router: router,
            repository: repository,
            observer: observer,
            output: output,
            selectedCategoryID: nil
        )

        await sut.fetchData()
        await sut.handleTapCreateCategory()

        XCTAssertEqual(router.openCategoryCreateCallsCount, 1)
    }

    func testObservedCategoryUpdatesRefreshVisibleListWithoutSelectingNewCategory() async {
        let presenter = ExpenseCategoryPickerPresentationLogicMock()
        let router = ExpenseCategoryPickerRoutingLogicMock()
        let observer = MainFlowDomainObserverProtocolMock()
        let (stream, continuation) = AsyncStream.makeStream(of: MainFlowCategoriesSnapshot.self)
        observer.subscribeCategoriesReturnValue = stream
        observer.currentCategoriesSnapshotReturnValue = .init()
        let repository = MainFlowDomainRepositoryProtocolMock()
        let output = ExpenseCategoryPickerOutputMock()
        let sut = makeSut(
            presenter: presenter,
            router: router,
            repository: repository,
            observer: observer,
            output: output,
            selectedCategoryID: nil
        )

        let travelPresented = expectation(description: "Travel category presented")
        travelPresented.assertForOverFulfill = false
        presenter.presentFetchedDataClosure = { data in
            if data.categories.map(\.id) == ["travel"] {
                travelPresented.fulfill()
            }
        }
        await sut.fetchData()
        let travelSnapshot = MainFlowCategoriesSnapshot(
            categories: [
                .init(id: "travel", name: "Travel", icon: "✈️", color: "#A0E7E5", amount: .zero, currency: "USD")
            ]
        )
        observer.currentCategoriesSnapshotReturnValue = travelSnapshot
        continuation.yield(travelSnapshot)
        await fulfillment(of: [travelPresented], timeout: 1.0)

        XCTAssertEqual(presenter.presentFetchedDataReceivedInvocations.last?.categories.map(\.id), ["travel"])
        XCTAssertNil(presenter.presentFetchedDataReceivedInvocations.last?.selectedCategoryID)
    }
}

private extension ExpenseCategoryPickerInteractorTests {
    func makeSut(
        presenter: ExpenseCategoryPickerPresentationLogic,
        router: ExpenseCategoryPickerRoutingLogic,
        repository: MainFlowDomainRepositoryProtocol,
        observer: MainFlowDomainObserverProtocol,
        output: ExpenseCategoryPickerOutput,
        selectedCategoryID: String?
    ) -> ExpenseCategoryPickerInteractor {
        ExpenseCategoryPickerInteractor(
            presenter: presenter,
            router: router,
            repository: repository,
            observer: observer,
            output: output,
            selectedCategoryID: selectedCategoryID
        )
    }

}
