//
//  DI.swift
//  Vault
//
//  Created by Егор Шкарин on 15.03.2026.
//

import Swinject

enum DI {
    static let assembler = Assembler([AppAssembly()])
    static let resolver: Resolver = assembler.resolver
}
