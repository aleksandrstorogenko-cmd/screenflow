//
//  View+Extensions.swift
//  ScreenFlow
//
//  Navigation sub-title if IOS 26+ and swipe back disabling
//

import SwiftUI
import UIKit


extension View {

    /// Extension for Conditional Modifiers: conditionally applies a transform to the view
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

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
    
    /// Apply animated scale and fade transition for item removal/insertion
    func animatedItemTransition() -> some View {
        self.transition(.asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .scale.combined(with: .opacity)
        ))
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
