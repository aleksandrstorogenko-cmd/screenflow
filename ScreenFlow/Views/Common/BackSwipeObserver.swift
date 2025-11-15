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

        init(onBackSwipeBegan: @escaping () -> Void) {
            self.onBackSwipeBegan = onBackSwipeBegan
        }

        @objc func handlePopGesture(_ gesture: UIGestureRecognizer) {
            // Реагируем только на начало жеста
            if gesture.state == .began {
                onBackSwipeBegan()
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
