//
//  ToastPresenter.swift
//  Vault
//
//  Created by Egor Shkarin on 16.03.2026.
//

import UIKit
import SnapKit

protocol ToastPresenting {
    @MainActor
    func present(
        state: ToastState,
        title: String,
        buttonText: String?,
        command: Command,
        threshold: TimeInterval
    )
}

extension ToastPresenting {
    @MainActor
    func present(
        state: ToastState,
        title: String,
        buttonText: String? = nil,
        command: Command
    ) {
        present(
            state: state,
            title: title,
            buttonText: buttonText,
            command: command,
            threshold: ToastPresenter.defaultThreshold
        )
    }

    @MainActor
    func present(
        state: ToastState,
        title: String,
        buttonText: String? = nil
    ) {
        present(
            state: state,
            title: title,
            buttonText: buttonText,
            command: .nope,
            threshold: ToastPresenter.defaultThreshold
        )
    }
}

final class ToastPresenter: ToastPresenting {
    static let defaultThreshold: TimeInterval = 3

    private enum Constants {
        static let horizontalInset: CGFloat = 16
        static let bottomInset: CGFloat = 24
        static let showAnimationDuration: TimeInterval = 0.28
        static let hideAnimationDuration: TimeInterval = 0.2
    }

    private let windowProvider: @MainActor () -> UIWindow?
    @MainActor
    private var currentToast: Toast?
    @MainActor
    private var dismissTask: Task<Void, Never>?

    @MainActor
    private(set) var viewModel: Toast.ViewModel = .init()

    init(
        windowProvider: @escaping @MainActor () -> UIWindow? = ToastPresenter.resolveCurrentWindow
    ) {
        self.windowProvider = windowProvider
    }

    @MainActor
    func present(
        state: ToastState,
        title: String,
        buttonText: String? = nil,
        command: Command = .nope,
        threshold: TimeInterval = ToastPresenter.defaultThreshold
    ) {
        let normalizedState = state.normalizedState
        let shouldShowButton = shouldShowButton(
            buttonText: buttonText,
            command: command
        )

        let buttonCommand: Command
        if shouldShowButton {
            buttonCommand = Command { [weak self] in
                command.execute()
                self?.dismissCurrentToast(animated: true)
            }
        } else {
            buttonCommand = .nope
        }

        let tapCommand = Command { [weak self] in
            self?.dismissCurrentToast(animated: true)
        }

        viewModel = Toast.ViewModel(
            state: normalizedState,
            title: Label.LabelViewModel(
                text: title,
                font: Typography.typographyMedium14,
                textColor: Asset.Colors.textAndIconPrimaryInverted.color,
                alignment: .left,
                numberOfLines: 0,
                lineBreakMode: .byWordWrapping
            ),
            icon: normalizedState.icon,
            backgroundColor: normalizedState.backgroundColor,
            buttonText: shouldShowButton ? buttonText : nil,
            buttonTextColor: Asset.Colors.interactiveElemetsPrimary.color,
            command: buttonCommand,
            tapCommand: tapCommand
        )

        showToast(
            with: viewModel,
            threshold: threshold
        )
    }
}

private extension ToastPresenter {
    @MainActor
    func shouldShowButton(
        buttonText: String?,
        command: Command
    ) -> Bool {
        guard let buttonText else {
            return false
        }

        return !buttonText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && command != .nope
    }

    @MainActor
    func showToast(
        with viewModel: Toast.ViewModel,
        threshold: TimeInterval
    ) {
        guard let window = windowProvider() else {
            return
        }

        dismissCurrentToast(animated: false)

        let toast = Toast()
        toast.apply(viewModel)

        window.addSubview(toast)
        toast.snp.makeConstraints { make in
            make.leading.trailing.equalTo(window.safeAreaLayoutGuide).inset(Constants.horizontalInset)
            make.bottom.equalTo(window.safeAreaLayoutGuide.snp.bottom).offset(-Constants.bottomInset)
        }

        window.layoutIfNeeded()

        let translationY = toast.bounds.height + Constants.bottomInset
        toast.alpha = 0
        toast.transform = CGAffineTransform(translationX: 0, y: translationY)

        UIView.animate(
            withDuration: Constants.showAnimationDuration,
            delay: 0,
            options: [.curveEaseOut, .allowUserInteraction]
        ) {
            toast.alpha = 1
            toast.transform = .identity
            window.layoutIfNeeded()
        }

        currentToast = toast
        scheduleDismiss(threshold: threshold)
    }

    @MainActor
    func scheduleDismiss(threshold: TimeInterval) {
        dismissTask?.cancel()

        guard threshold > 0 else {
            dismissTask = nil
            return
        }

        dismissTask = Task { [weak self] in
            let nanoseconds = UInt64(max(0, threshold) * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanoseconds)

            guard !Task.isCancelled else {
                return
            }

            self?.dismissCurrentToast(animated: true)
        }
    }

    @MainActor
    func dismissCurrentToast(animated: Bool) {
        dismissTask?.cancel()
        dismissTask = nil

        guard let currentToast else {
            return
        }

        self.currentToast = nil

        let removeToast = {
            currentToast.removeFromSuperview()
        }

        guard animated else {
            removeToast()
            return
        }

        let translationY = currentToast.bounds.height + Constants.bottomInset
        UIView.animate(
            withDuration: Constants.hideAnimationDuration,
            delay: 0,
            options: [.curveEaseIn, .allowUserInteraction]
        ) {
            currentToast.alpha = 0
            currentToast.transform = CGAffineTransform(translationX: 0, y: translationY)
        } completion: { _ in
            removeToast()
        }
    }

    @MainActor
    static func resolveCurrentWindow() -> UIWindow? {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }

        let activeScenes = scenes.filter {
            $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive
        }

        for scene in activeScenes + scenes {
            if let keyWindow = scene.windows.first(where: \.isKeyWindow) {
                return keyWindow
            }

            if let window = scene.windows.last {
                return window
            }
        }

        return nil
    }
}

private extension ToastState {
    var normalizedState: ToastState {
        switch self {
        case .neuteral:
            return .neutral
        default:
            return self
        }
    }

    var icon: Toast.Icon {
        switch self {
        case .error:
            return .sfSymbol(name: "exclamationmark.circle.fill")
        case .neutral, .neuteral:
            return .sfSymbol(name: "info.circle.fill")
        case .success:
            return .none
        }
    }

    var backgroundColor: UIColor {
        switch self {
        case .error:
            return Asset.Colors.errorColor.color
        case .success:
            return .systemGreen
        case .neutral, .neuteral:
            return UIColor.black.withAlphaComponent(0.8)
        }
    }
}
