//
//  BackSwipeObserver.swift
//  ScreenFlow
//
//  Observer for back swipe gesture (interactive pop)
//

import SwiftUI
import UIKit

/// Наблюдатель за жестом "свайп назад" (interactive pop)
struct BackSwipeObserver: UIViewControllerRepresentable {
    let onBackSwipeBegan: () -> Void

    class Coordinator: NSObject {
        let onBackSwipeBegan: () -> Void
        private var hasTriggered = false
        private weak var view: UIView?

        init(onBackSwipeBegan: @escaping () -> Void) {
            self.onBackSwipeBegan = onBackSwipeBegan
        }

        @objc func handlePopGesture(_ gesture: UIGestureRecognizer) {
            guard let panGesture = gesture as? UIPanGestureRecognizer,
                  let view = self.view else {
                return
            }

            switch gesture.state {
            case .began:
                // Reset the trigger flag when gesture begins
                hasTriggered = false

            case .changed:
                // Only trigger if we haven't already and the swipe has progressed far enough
                guard !hasTriggered else { return }

                let translation = panGesture.translation(in: view)
                let velocity = panGesture.velocity(in: view)

                // Calculate progress as a percentage of screen width
                let progress = translation.x / view.bounds.width

                // Trigger if either:
                // 1. User has swiped past 40% of screen width
                // 2. User is swiping with significant velocity (> 500 pts/sec) and has moved at least 15% of screen
                let hasEnoughProgress = progress > 0.4
                let hasFastSwipe = velocity.x > 500 && progress > 0.15

                if hasEnoughProgress || hasFastSwipe {
                    hasTriggered = true
                    onBackSwipeBegan()
                }

            case .ended, .cancelled, .failed:
                // Reset trigger flag when gesture ends
                hasTriggered = false

            default:
                break
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onBackSwipeBegan: onBackSwipeBegan)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()

        // navController появляется чуть позже, поэтому идём в main.async
        DispatchQueue.main.async {
            guard
                let nav = controller.navigationController,
                let gesture = nav.interactivePopGestureRecognizer
            else { return }

            // Store reference to the view for translation calculations
            context.coordinator.view = nav.view

            gesture.addTarget(
                context.coordinator,
                action: #selector(Coordinator.handlePopGesture(_:))
            )
        }

        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Ничего обновлять не нужно
    }
}
