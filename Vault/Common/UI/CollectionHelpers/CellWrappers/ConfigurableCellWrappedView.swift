// Created by Egor Shkarin on 30.03.2026

import Foundation

@MainActor
protocol ConfigurableCellWrappedView: AnyObject {
    associatedtype ViewModel

    func configure(with viewModel: ViewModel)
}
