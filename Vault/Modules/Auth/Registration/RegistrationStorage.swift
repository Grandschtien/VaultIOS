//
//  RegistrationStorage.swift
//  Vault
//
//  Created by Егор Шкарин on 16.03.2026.
//

import Foundation

struct RegistrationDraft: Equatable, Sendable {
    var email: String
    var password: String
    var confirmPassword: String
    var name: String
    var currencyCode: String?

    init(
        email: String = "",
        password: String = "",
        confirmPassword: String = "",
        name: String = "",
        currencyCode: String? = nil
    ) {
        self.email = email
        self.password = password
        self.confirmPassword = confirmPassword
        self.name = name
        self.currencyCode = currencyCode
    }
}

protocol RegistrationStorageProtocol: Sendable {
    func loadDraft() async -> RegistrationDraft
    func saveDraft(_ draft: RegistrationDraft) async
    func clear() async
}

actor RegistrationStorage: RegistrationStorageProtocol {
    private var draft: RegistrationDraft = .init()

    func loadDraft() async -> RegistrationDraft {
        draft
    }

    func saveDraft(_ draft: RegistrationDraft) async {
        self.draft = draft
    }

    func clear() async {
        draft = .init()
    }
}
