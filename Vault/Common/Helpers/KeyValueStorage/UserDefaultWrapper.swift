//
//  UserDefaultWrapper.swift
//  Vault
//
//  Created by Егор Шкарин on 14.03.2026.
//

import Foundation

@propertyWrapper
struct UserDefault<Value: Codable> {
    private let key: UserDefaultKeys
    private let defaultValue: Value
    private let storage: KeyValueStorage
    
    init(
        _ key: UserDefaultKeys,
        default defaultValue: Value,
        storage: KeyValueStorage = UserDefaultsStorage()
    ) {
        self.key = key
        self.defaultValue = defaultValue
        self.storage = storage
    }
    
    var wrappedValue: Value {
        get {
            storage.get(Value.self, forKey: key.rawValue) ?? defaultValue
        }
        set {
            storage.set(newValue, forKey: key.rawValue)
        }
    }
}
