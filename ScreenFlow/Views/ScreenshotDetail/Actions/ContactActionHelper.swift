//
//  ContactActionHelper.swift
//  ScreenFlow
//
//  Helper for contact-related actions using ActionExecutor
//

import Foundation

/// Helper for creating and saving contacts from screenshots
@MainActor
struct ContactActionHelper {

    /// Result of contact action
    enum Result {
        case success
        case failure(title: String, message: String)
    }

    /// Execute contact save action using ActionExecutor
    static func saveContact(from screenshot: Screenshot) async -> Result {
        guard let extracted = screenshot.extractedData else {
            return .failure(title: "Cannot Save Contact", message: "No contact information found")
        }

        // Verify we have at least some contact data
        guard extracted.contactName != nil ||
              !extracted.emails.isEmpty ||
              !extracted.phoneNumbers.isEmpty else {
            return .failure(title: "Cannot Save Contact", message: "No contact information found")
        }

        // Create SmartAction
        let action = SmartActionFactory.createContactAction(from: extracted)

        // Execute using ActionExecutor
        let success = await ActionExecutor.shared.execute(action)

        if success {
            return .success
        } else {
            return .failure(title: "Failed to Save Contact", message: "Could not save contact information")
        }
    }
}
