//
//  ViewModelStoreOptions.swift
//  Vault
//
//  Created by Егор Шкарин on 07.03.2026.
//

import Foundation

public struct ViewModelStoreOptions: OptionSet {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static let reschedule = ViewModelStoreOptions(rawValue: 1 << 0)
    public static let ignoreInitial = ViewModelStoreOptions(rawValue: 1 << 1)
    
    public static let `default`: ViewModelStoreOptions = [.reschedule, .ignoreInitial]
    public static let applyInitial: ViewModelStoreOptions = .reschedule
    public static let doNotReschedule: ViewModelStoreOptions = .ignoreInitial

}
