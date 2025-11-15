//
//  TextActionHelper.swift
//  ScreenFlow
//
//  Helper for text-related actions (copy, note)
//

import Foundation
import UIKit

/// Helper for text manipulation actions
/// TODO: Refactor to use ActionExecutor service instead of inline implementation
struct TextActionHelper {

    /// Result of text action
    enum Result {
        case success(title: String, message: String)
        case failure(title: String, message: String)
        case presentShareSheet(text: String)
    }

    /// Copy text to clipboard
    static func copyText(from screenshot: Screenshot) -> Result {
        guard let extracted = screenshot.extractedData else {
            return .failure(title: "No Data Available", message: "This screenshot hasn't been analyzed yet")
        }

        guard let text = extracted.fullText, !text.isEmpty else {
            return .failure(title: "No Text Found", message: "No text detected on this screenshot")
        }

        UIPasteboard.general.string = text
        return .success(title: "Text Copied", message: "Text copied to clipboard successfully")
    }

    /// Create a note from text
    static func createNote(from screenshot: Screenshot) -> Result {
        guard let extracted = screenshot.extractedData else {
            return .failure(title: "No Data Available", message: "This screenshot hasn't been analyzed yet.")
        }

        guard let fullText = extracted.fullText?.trimmingCharacters(in: .whitespacesAndNewlines),
              !fullText.isEmpty else {
            return .failure(title: "No Text Found", message: "No text detected on this screenshot.")
        }

        guard fullText.count >= 20 else {
            return .failure(title: "Needs More Text", message: "At least 20 characters are required to create a note.")
        }

        return .presentShareSheet(text: fullText)
    }

    /// Present share sheet for text
    static func presentShareSheet(with text: String) -> Bool {
        // Import NoteTextActivityItemSource from Services if needed
        let activityVC = UIActivityViewController(
            activityItems: [NoteTextActivityItemSource(text: text)],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {

            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootVC.view
                popover.sourceRect = CGRect(
                    x: rootVC.view.bounds.midX,
                    y: rootVC.view.bounds.midY,
                    width: 0,
                    height: 0
                )
                popover.permittedArrowDirections = []
            }

            var topController = rootVC
            while let presented = topController.presentedViewController {
                topController = presented
            }

            topController.present(activityVC, animated: true)
            return true
        } else {
            return false
        }
    }
}

// Note: NoteTextActivityItemSource is defined in Services/ActionExecution/TextActionHandler.swift
// Import it from there or create a shared location if needed
