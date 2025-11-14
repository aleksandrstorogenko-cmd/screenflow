//
//  CommunicationActionHandler.swift
//  ScreenFlow
//
//  Handles communication actions (link, call, email)
//

import Foundation
import UIKit

/// Handles link, call, and email actions
@MainActor
final class CommunicationActionHandler {
    /// Execute link action
    func executeLink(_ action: SmartAction) async -> Bool {
        guard let urlString = ActionDataDecoder.decodeString(action.actionData),
              let url = URL(string: urlString) else {
            print("Failed to decode URL")
            return false
        }

        if UIApplication.shared.canOpenURL(url) {
            await UIApplication.shared.open(url)
            print("Opened URL: \(urlString)")
            return true
        } else {
            print("Cannot open URL: \(urlString)")
            return false
        }
    }

    /// Execute call action
    func executeCall(_ action: SmartAction) async -> Bool {
        guard let phoneNumber = ActionDataDecoder.decodeString(action.actionData) else {
            print("Failed to decode phone number")
            return false
        }

        // Clean phone number (remove non-digits except +)
        let cleanedNumber = phoneNumber.replacingOccurrences(
            of: "[^0-9+]",
            with: "",
            options: .regularExpression
        )

        let urlString = "tel://\(cleanedNumber)"
        guard let url = URL(string: urlString) else {
            print("Failed to create tel URL")
            return false
        }

        if UIApplication.shared.canOpenURL(url) {
            await UIApplication.shared.open(url)
            print("Initiated call to: \(phoneNumber)")
            return true
        } else {
            print("Cannot make phone calls on this device")
            return false
        }
    }

    /// Execute email action
    func executeEmail(_ action: SmartAction) async -> Bool {
        guard let email = ActionDataDecoder.decodeString(action.actionData) else {
            print("Failed to decode email")
            return false
        }

        let urlString = "mailto:\(email)"
        guard let url = URL(string: urlString) else {
            print("Failed to create mailto URL")
            return false
        }

        if UIApplication.shared.canOpenURL(url) {
            await UIApplication.shared.open(url)
            print("Opened email composer for: \(email)")
            return true
        } else {
            print("Cannot open email")
            return false
        }
    }
}
