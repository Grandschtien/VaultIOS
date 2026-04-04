import UIKit
import Nivelir

extension ScreenThenable where Current: UIViewController {
    func dimiss(
        animated: Bool = true
    ) -> Self {
        presenting { route in
            route.dismiss(animated: animated)
        }
    }

    func dimissAndPresent<New: Screen>(
        _ screen: New,
        animated: Bool = true
    ) -> Self where New.Container: UIViewController {
        presenting { route in
            route
                .dismiss(animated: animated)
                .present(screen, animated: animated)
        }
    }
}
