//
//  RootViewController.swift
//  Vault
//
//  Created by Егор Шкарин on 14.03.2026.
//

import UIKit
import SnapKit
import Nivelir

final class RootViewController: UINavigationController, Screen {
    private var currentChildViewController: UIViewController?

    func setRoot(_ viewController: UIViewController) {
        guard currentChildViewController !== viewController else {
            return
        }

        currentChildViewController?.willMove(toParent: nil)

        addChild(viewController)
        view.addSubview(viewController.view)

        viewController.view.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        viewController.didMove(toParent: self)

        if let previousViewController = currentChildViewController {
            previousViewController.view.removeFromSuperview()
            previousViewController.removeFromParent()
        }

        currentChildViewController = viewController
    }
}
