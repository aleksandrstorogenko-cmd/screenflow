//
//  CommunicationActionHelper.swift
//  ScreenFlow
//
//  Helper for communication actions (call, email)
//

import Foundation
import UIKit

/// Helper for executing communication actions
/// TODO: Refactor to use ActionExecutor service instead of inline implementation
struct CommunicationActionHelper {

    /// Result of communication action
    enum Result {
        case success
        case failure(title: String, message: String)
    }

    /// Make a phone call
    static func makeCall(from screenshot: Screenshot) -> Result {
        guard let extracted = screenshot.extractedData else {
            return .failure(title: "No Data Available", message: "This screenshot hasn't been analyzed yet")
        }

        let phoneNumber = extracted.phoneNumbers.first ?? extracted.contactPhone ?? ""

        guard !phoneNumber.isEmpty else {
            return .failure(title: "No Phone Number", message: "No phone number found on this screenshot")
        }

        let cleaned = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()

        guard !cleaned.isEmpty else {
            return .failure(title: "Invalid Phone Number", message: "The phone number format is invalid")
        }

        if let url = URL(string: "tel://\(cleaned)") {
            UIApplication.shared.open(url)
            return .success
        } else {
            return .failure(title: "Cannot Make Call", message: "Unable to initiate phone call")
        }
    }

    /// Send an email
    static func sendEmail(from screenshot: Screenshot) -> Result {
        guard let extracted = screenshot.extractedData else {
            return .failure(title: "No Data Available", message: "This screenshot hasn't been analyzed yet")
        }

        let email = extracted.emails.first ?? extracted.contactEmail ?? ""

        guard !email.isEmpty else {
            return .failure(title: "No Email Address", message: "No email address found on this screenshot")
        }

        if let url = URL(string: "mailto:\(email)") {
            UIApplication.shared.open(url)
            return .success
        } else {
            return .failure(title: "Invalid Email", message: "The email address format is invalid")
        }
    }
}
