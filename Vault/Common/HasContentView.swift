//
//  HasContentView.swift
//  Vault
//
//  Created by Егор Шкарин on 07.03.2026.
//

import UIKit

protocol HasContentView: UIViewController {
    associatedtype ContentView: UIView
}

extension HasContentView {
    var contentView: ContentView {
        view as! ContentView
    }
}
