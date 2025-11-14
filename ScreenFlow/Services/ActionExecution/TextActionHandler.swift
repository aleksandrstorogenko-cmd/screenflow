//
//  TextActionHandler.swift
//  ScreenFlow
//
//  Handles text actions (copy, note, share)
//

import Foundation
import UIKit
import UniformTypeIdentifiers

/// Handles text manipulation actions
@MainActor
final class TextActionHandler {
    /// Execute copy action
    func executeCopy(_ action: SmartAction) async -> Bool {
        guard let text = ActionDataDecoder.decodeString(action.actionData) else {
            print("Failed to decode text")
            return false
        }

        UIPasteboard.general.string = text
        print("Copied text to clipboard (\(text.count) characters)")
        return true
    }

    /// Execute note action
    func executeNote(_ action: SmartAction) async -> Bool {
        guard let decoded = ActionDataDecoder.decodeString(action.actionData)?
                .trimmingCharacters(in: .whitespacesAndNewlines),
              !decoded.isEmpty else {
            print("Failed to decode text")
            return false
        }

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("Failed to get root view controller for note share")
            return false
        }

        let itemSource = NoteTextActivityItemSource(text: decoded)
        let activityVC = UIActivityViewController(
            activityItems: [itemSource],
            applicationActivities: nil
        )

        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = rootViewController.view
            popover.sourceRect = CGRect(
                x: rootViewController.view.bounds.midX,
                y: rootViewController.view.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }

        var topController = rootViewController
        while let presented = topController.presentedViewController {
            topController = presented
        }

        topController.present(activityVC, animated: true)
        print("Presented share sheet for note text (\(decoded.count) chars)")
        return true
    }

    /// Execute share action
    func executeShare(screenshot: Screenshot) async -> Bool {
        // Get the current window scene's key window
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("Failed to get root view controller")
            return false
        }

        // Load the screenshot image
        return await withCheckedContinuation { continuation in
            PhotoLibraryService.shared.fetchFullImage(for: screenshot) { image in
                guard let image = image else {
                    print("Failed to load image for sharing")
                    continuation.resume(returning: false)
                    return
                }

                // Create activity view controller
                let activityVC = UIActivityViewController(
                    activityItems: [image],
                    applicationActivities: nil
                )

                // For iPad - configure popover
                if let popover = activityVC.popoverPresentationController {
                    popover.sourceView = rootViewController.view
                    popover.sourceRect = CGRect(
                        x: rootViewController.view.bounds.midX,
                        y: rootViewController.view.bounds.midY,
                        width: 0,
                        height: 0
                    )
                    popover.permittedArrowDirections = []
                }

                // Present on main thread
                Task { @MainActor in
                    // Find the topmost view controller
                    var topController = rootViewController
                    while let presented = topController.presentedViewController {
                        topController = presented
                    }

                    topController.present(activityVC, animated: true) {
                        print("Share sheet presented")
                        continuation.resume(returning: true)
                    }
                }
            }
        }
    }
}

/// Provides consistent plain-text payloads for Notes/Quick Note
final class NoteTextActivityItemSource: NSObject, UIActivityItemSource {
    private let text: String

    init(text: String) {
        self.text = text
        super.init()
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return text as NSString
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return text as NSString
    }

    func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
        return UTType.plainText.identifier
    }

    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return String(trimmed.prefix(60))
    }
}
