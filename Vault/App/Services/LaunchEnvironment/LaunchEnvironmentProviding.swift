// Created by Egor Shkarin on 28.10.2026

import Foundation

// sourcery: AutoMockable
protocol LaunchEnvironmentProviding {
    var apiBaseURL: URL? { get }
    var isQAMode: Bool { get }
    var qaSession: String? { get }
}
