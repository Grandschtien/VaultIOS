//
//  Reusable.swift
//  Vault
//
//  Created by Егор Шкарин on 30.03.2026.
//

import Foundation

@MainActor
protocol Reusable: AnyObject {
    static var reuseId: String { get }
}

extension Reusable {
    static var reuseId: String {
        String(describing: Self.self)
    }
}
