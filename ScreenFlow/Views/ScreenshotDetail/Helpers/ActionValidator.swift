//
//  ActionValidator.swift
//  ScreenFlow
//
//  Validates which actions are available for a screenshot
//

import Foundation

/// Validates which actions can be performed on a screenshot based on extracted data
struct ActionValidator {

    /// Check if contact can be saved
    static func canSaveContact(_ screenshot: Screenshot) -> Bool {
        guard let extracted = screenshot.extractedData else { return false }
        return extracted.contactName != nil ||
               !extracted.emails.isEmpty ||
               !extracted.phoneNumbers.isEmpty
    }

    /// Check if event can be added to calendar
    static func canAddToCalendar(_ screenshot: Screenshot) -> Bool {
        guard let extracted = screenshot.extractedData else { return false }
        return extracted.eventName != nil || extracted.eventDate != nil
    }

    /// Check if bookmark can be saved
    static func canSaveBookmark(_ screenshot: Screenshot) -> Bool {
        guard let extracted = screenshot.extractedData else { return false }
        return !extracted.urls.isEmpty
    }

    /// Check if URL can be opened
    static func canOpenURL(_ screenshot: Screenshot) -> Bool {
        guard let extracted = screenshot.extractedData else { return false }
        return !extracted.urls.isEmpty
    }

    /// Check if map can be opened
    static func canOpenMap(_ screenshot: Screenshot) -> Bool {
        guard let extracted = screenshot.extractedData else { return false }
        return !extracted.addresses.isEmpty || extracted.eventLocation != nil
    }

    /// Check if phone call can be made
    static func canMakeCall(_ screenshot: Screenshot) -> Bool {
        guard let extracted = screenshot.extractedData else { return false }
        return !extracted.phoneNumbers.isEmpty || extracted.contactPhone != nil
    }

    /// Check if email can be sent
    static func canSendEmail(_ screenshot: Screenshot) -> Bool {
        guard let extracted = screenshot.extractedData else { return false }
        return !extracted.emails.isEmpty || extracted.contactEmail != nil
    }

    /// Check if text can be copied
    static func canCopyText(_ screenshot: Screenshot) -> Bool {
        guard let extracted = screenshot.extractedData else { return false }
        return extracted.fullText != nil && !(extracted.fullText?.isEmpty ?? true)
    }
}
