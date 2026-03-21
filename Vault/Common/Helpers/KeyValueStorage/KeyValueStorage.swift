//
//  OnboardingStateStorage.swift
//  Vault
//
//  Created by Egor Shkarin on 14.03.2026.
//

import Foundation

protocol KeyValueStorage {
    func set<Value: Codable>(_ value: Value, forKey key: String)
    func get<Value: Codable>(_ type: Value.Type, forKey key: String) -> Value?
    func removeValue(forKey key: String)
}

final class UserDefaultsStorage: KeyValueStorage {
    
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
    
    func set<Value: Codable>(_ value: Value, forKey key: String) {
        if let data = try? encoder.encode(value) {
            defaults.set(data, forKey: key)
        }
    }
    
    func get<Value: Codable>(_ type: Value.Type, forKey key: String) -> Value? {
        guard let data = defaults.data(forKey: key) else {
            return nil
        }
        return try? decoder.decode(type, from: data)
    }
    
    func removeValue(forKey key: String) {
        defaults.removeObject(forKey: key)
    }
}
