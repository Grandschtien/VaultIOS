// Created by Egor Shkarin on 24.03.2026

import Foundation

struct CategoryCreateRequestDTO: Codable, Equatable, Sendable {
    let name: String
    let icon: String
    let color: String
}
