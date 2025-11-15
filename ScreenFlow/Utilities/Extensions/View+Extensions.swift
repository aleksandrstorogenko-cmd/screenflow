//
//  View+Extensions.swift
//  ScreenFlow
//
//  Navigation sub-title if IOS 26+ and swipe back disabling
//

import SwiftUI
import UIKit


extension View {
    @ViewBuilder
    func navigationSubtitleIfAvailable(_ text: String) -> some View {
        if #available(iOS 26.0, *) {
            self.navigationSubtitle(text)
        } else {
            self
        }
    }

    /// Disable swipe back gesture in navigation
    func disableSwipeBack() -> some View {
        self.background(SwipeBackDisabler())
    }
}

/// UIViewControllerRepresentable to disable swipe back gesture
private struct SwipeBackDisabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        SwipeBackDisablerViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No updates needed
    }

    class SwipeBackDisablerViewController: UIViewController {
        override func didMove(toParent parent: UIViewController?) {
            super.didMove(toParent: parent)

            if let navigationController = navigationController {
                navigationController.interactivePopGestureRecognizer?.isEnabled = false
            }
        }
    }
}
