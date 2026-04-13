//
//  RootViewController.swift
//  Vault
//
//  Created by Егор Шкарин on 14.03.2026.
//

import UIKit
import SnapKit
import Nivelir

final class RootAuthViewController: UINavigationController, Screen {
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
    }
}

private extension RootAuthViewController {
    func configureNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = Asset.Colors.backgroundPrimary.color
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [
            .foregroundColor: Asset.Colors.textAndIconPrimary.color,
            .font: Typography.typographyBold20
        ]

        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance
        navigationBar.tintColor = Asset.Colors.textAndIconPrimary.color
        navigationBar.prefersLargeTitles = false
    }
}
