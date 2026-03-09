//
//  ViewModelStore.swift
//  Vault
//
//  Created by Егор Шкарин on 07.03.2026.
//

internal import Combine
import Foundation

final class ViewModelStore<ViewModel: Equatable>: ObservableObject {
    typealias Publisher = AnyPublisher<
        Published<ViewModel>.Publisher.Output,
        Published<ViewModel>.Publisher.Failure
    >
    
    private let publisher: Publisher
    private let options: ViewModelStoreOptions
    
    public private(set) var viewModel: ViewModel
    
    private var cancellables: Set<AnyCancellable> = []
    
    public var onViewModelChange: ((ViewModel) -> Void)? {
        didSet {
            cancellables.removeAll()
            publisher
                .removeDuplicates()
                .dropFirstIfNeeded(options: options)
                .sink { [weak self] viewModel in
                    self?.onViewModelChange?(viewModel)
                    self?.objectWillChange.send()
                    self?.viewModel = viewModel
                }
                .store(in: &cancellables)
        }
    }
    
    init(
        viewModel: ViewModel,
        options: ViewModelStoreOptions = .default,
        publisher: Published<ViewModel>.Publisher
    ) {
        self.options = options
        self.viewModel = viewModel

        if options.contains(.reschedule) {
            self.publisher = publisher.receive(on: DispatchQueue.main).eraseToAnyPublisher()
        } else {
            self.publisher = publisher.eraseToAnyPublisher()
        }
    }
}

extension Publisher {
    func dropFirstIfNeeded(options: ViewModelStoreOptions) -> AnyPublisher<Output, Failure> {
        if options.contains(.ignoreInitial) {
            return dropFirst()
                .eraseToAnyPublisher()
        } else {
            return eraseToAnyPublisher()
        }
    }
}
