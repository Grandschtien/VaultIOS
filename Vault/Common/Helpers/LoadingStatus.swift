//
//  LoadingStatus.swift
//  Vault
//
//  Created by Егор Шкарин on 15.03.2026.
//

import Foundation

enum LoadingStatus {
    case idle
    case loading
    case loaded
    case failed(Error)
}
