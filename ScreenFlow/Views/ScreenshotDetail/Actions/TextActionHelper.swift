//
//  TextActionHelper.swift
//  ScreenFlow
//
//  Helper for text-related actions (copy, note) using ActionExecutor
//

import Foundation

/// Helper for text manipulation actions
@MainActor
struct TextActionHelper {

    /// Result of text action
    enum Result {
        case success(title: String, message: String)
        case failure(title: String, message: String)
    }

    /// Copy text to clipboard using ActionExecutor
    static func copyText(from screenshot: Screenshot) async -> Result {
        guard let extracted = screenshot.extractedData else {
            return .failure(title: "No Data Available", message: "This screenshot hasn't been analyzed yet")
        }

        guard let text = extracted.fullText, !text.isEmpty else {
            return .failure(title: "No Text Found", message: "No text detected on this screenshot")
        }

        // Create SmartAction
        let action = SmartActionFactory.createCopyAction(text: text)

        // Execute using ActionExecutor
        let success = await ActionExecutor.shared.execute(action)

        if success {
            return .success(title: "Text Copied", message: "Text copied to clipboard successfully")
        } else {
            return .failure(title: "Failed to Copy", message: "Could not copy text to clipboard")
        }
    }

    /// Create a note from text using ActionExecutor
    static func createNote(from screenshot: Screenshot) async -> Result {
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

        // Create SmartAction
        let action = SmartActionFactory.createNoteAction(text: fullText)

        // Execute using ActionExecutor
        let success = await ActionExecutor.shared.execute(action)

        if success {
            return .success(title: "Note Created", message: "Note created successfully")
        } else {
            return .failure(title: "Failed to Create Note", message: "Could not create note")
        }
    }
}
