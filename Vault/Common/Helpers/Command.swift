//
//  Command.swift
//  Vault
//
//  Created by Егор Шкарин on 09.03.2026.
//

import Foundation

public struct Command: Equatable {
    public typealias Action = () async -> Void

    private let id: UUID
    private let action: Action?

    // MARK: - Init

    init(action: Action?, id: UUID = UUID()) {
        self.id = id
        self.action = action
    }

    // MARK: - Default cases

    public static let nope = Command(action: nil)
    public static let any = Command(action: {})

    // MARK: - Execute

    public func execute() {
        Task { await action?() }
    }

    public func executeAsync() async {
        await action?()
    }

    // MARK: - State
    
    public static func == (lhs: Command, rhs: Command) -> Bool {
        lhs.id == rhs.id
    }
}

public struct CommandOf<Input>: Equatable {
    public typealias Action = (Input) async -> Void

    private let id: UUID
    private let action: Action?

    // MARK: - Init

    init(action: Action?, id: UUID = UUID()) {
        self.id = id
        self.action = action
    }

    // MARK: - Execute

    public func execute(_ input: Input) {
        Task { await action?(input) }
    }
    
    public static func == (lhs: CommandOf, rhs: CommandOf) -> Bool {
        lhs.id == rhs.id
    }
}
