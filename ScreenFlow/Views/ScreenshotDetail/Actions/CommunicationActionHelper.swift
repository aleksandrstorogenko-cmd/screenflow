//
//  CommunicationActionHelper.swift
//  ScreenFlow
//
//  Helper for communication actions (call, email) using ActionExecutor
//

import Foundation

/// Helper for executing communication actions
@MainActor
struct CommunicationActionHelper {

    /// Result of communication action
    enum Result {
        case success
        case failure(title: String, message: String)
    }

    /// Make a phone call using ActionExecutor
    static func makeCall(from screenshot: Screenshot) async -> Result {
        guard let extracted = screenshot.extractedData else {
            return .failure(title: "No Data Available", message: "This screenshot hasn't been analyzed yet")
        }

        let phoneNumber = extracted.phoneNumbers.first ?? extracted.contactPhone ?? ""

        guard !phoneNumber.isEmpty else {
            return .failure(title: "No Phone Number", message: "No phone number found on this screenshot")
        }

        // Create SmartAction
        let action = SmartActionFactory.createCallAction(phoneNumber: phoneNumber)

        // Execute using ActionExecutor
        let success = await ActionExecutor.shared.execute(action)

        if success {
            return .success
        } else {
            return .failure(title: "Failed to Make Call", message: "Could not initiate phone call")
        }
    }

    /// Send an email using ActionExecutor
    static func sendEmail(from screenshot: Screenshot) async -> Result {
        guard let extracted = screenshot.extractedData else {
            return .failure(title: "No Data Available", message: "This screenshot hasn't been analyzed yet")
        }

        let email = extracted.emails.first ?? extracted.contactEmail ?? ""

        guard !email.isEmpty else {
            return .failure(title: "No Email Address", message: "No email address found on this screenshot")
        }

        // Create SmartAction
        let action = SmartActionFactory.createEmailAction(email: email)

        // Execute using ActionExecutor
        let success = await ActionExecutor.shared.execute(action)

        if success {
            return .success
        } else {
            return .failure(title: "Failed to Send Email", message: "Could not open email client")
        }
    }
}
