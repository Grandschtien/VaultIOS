//
//  Command.swift
//  Vault
//
//  Created by Егор Шкарин on 09.03.2026.
//

import Foundation

public struct Command {
    public typealias Action = () -> Void

    private let action: Action?

    // MARK: - Init

    private init(action: Action?) {
        self.action = action
    }

    // MARK: - Builders

    public static func make(_ action: @escaping Action) -> Command {
        Command(action: action)
    }

    // MARK: - Default cases

    public static let nope = Command(action: nil)
    public static let any = Command(action: {})

    // MARK: - Execute

    public func execute() {
        action?()
    }

    // MARK: - State

    public var hasAction: Bool {
        action != nil
    }

    public var isNope: Bool {
        action == nil
    }
}

public struct CommandOf<Input> {
    public typealias Action = (Input) -> Void

    private let action: Action?

    // MARK: - Init

    private init(action: Action?) {
        self.action = action
    }

    // MARK: - Builders

    public static func make(_ action: @escaping Action) -> CommandOf<Input> {
        CommandOf<Input>(action: action)
    }

    // MARK: - Execute

    public func execute(_ input: Input) {
        action?(input)
    }
}
