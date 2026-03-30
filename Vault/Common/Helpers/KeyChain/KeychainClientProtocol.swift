//
//  KeychainClientProtocol.swift
//  Vault
//
//  Created by Егор Шкарин on 15.03.2026.
//

import Security
import Foundation

public protocol KeychainClientProtocol {
    func set(_ data: Data, forAccount account: String, service: String)
    func getData(forAccount account: String, service: String) -> Data?
    func removeData(forAccount account: String, service: String)
    func removeAll()
}

public final class KeychainClient: KeychainClientProtocol {
    public func set(_ data: Data, forAccount account: String, service: String) {
        let baseQuery = query(forAccount: account, service: service)
        SecItemDelete(baseQuery as CFDictionary)

        var addQuery = baseQuery
        addQuery[kSecValueData] = data
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    public func getData(forAccount account: String, service: String) -> Data? {
        var requestQuery = query(forAccount: account, service: service)
        requestQuery[kSecReturnData] = true
        requestQuery[kSecMatchLimit] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(requestQuery as CFDictionary, &result)

        guard status == errSecSuccess else {
            return nil
        }

        return result as? Data
    }

    public func removeData(forAccount account: String, service: String) {
        let baseQuery = query(forAccount: account, service: service)
        SecItemDelete(baseQuery as CFDictionary)
    }

    public func removeAll() {
        let secItemClasses = [
            kSecClassGenericPassword,
            kSecClassInternetPassword,
            kSecClassCertificate,
            kSecClassKey,
            kSecClassIdentity
        ]

        secItemClasses.forEach { secClass in
            let query: [CFString: Any] = [kSecClass: secClass]
            SecItemDelete(query as CFDictionary)
        }
    }
}

private extension KeychainClient {
    func query(forAccount account: String, service: String) -> [CFString: Any] {
        [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
    }
}
