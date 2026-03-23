//
//  LoadingStatus.swift
//  Vault
//
//  Created by Егор Шкарин on 15.03.2026.
//

import Foundation

enum LoadingStatus: Equatable {
    case idle
    case loading
    case loaded
    case failed(CommonError)
}
