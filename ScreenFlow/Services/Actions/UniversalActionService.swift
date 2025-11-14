//
//  UniversalActionService.swift
//  ScreenFlow
//
//  Universal action service - lets user choose action for any screenshot
//

import Foundation
import SwiftUI

/// Universal action that can be performed on any screenshot
struct UniversalAction: Identifiable {
    let id = UUID()
    let type: UniversalActionType
    let title: String
    let icon: String
    let description: String
    let color: Color
}

/// All possible actions user can perform on screenshots
enum UniversalActionType: String, CaseIterable {
    case saveContact = "save_contact"
    case createNote = "create_note"
    case addToCalendar = "add_to_calendar"
    case saveBookmark = "save_bookmark"
    case openMap = "open_map"
    case makeCall = "make_call"
    case sendEmail = "send_email"
    case copyText = "copy_text"
    case shareImage = "share_image"
    case saveToPhotos = "save_to_photos"
    case openURL = "open_url"

    var displayInfo: (title: String, icon: String, description: String, color: Color) {
        switch self {
        case .saveContact:
            return ("Save to Contacts", "person.crop.circle.badge.plus", "Extract contact info and save", .blue)
        case .createNote:
            return ("Create Note", "note.text.badge.plus", "Create note with text or image", .yellow)
        case .addToCalendar:
            return ("Add to Calendar", "calendar.badge.plus", "Extract event and add to calendar", .red)
        case .saveBookmark:
            return ("Save Bookmark", "bookmark.fill", "Save URL as browser bookmark", .orange)
        case .openMap:
            return ("Open in Maps", "map.fill", "Open address in Maps app", .green)
        case .makeCall:
            return ("Make Call", "phone.fill", "Call phone number", .green)
        case .sendEmail:
            return ("Send Email", "envelope.fill", "Compose email", .blue)
        case .copyText:
            return ("Copy Text", "doc.on.doc", "Copy all text to clipboard", .gray)
        case .shareImage:
            return ("Share", "square.and.arrow.up", "Share screenshot", .blue)
        case .saveToPhotos:
            return ("Save to Photos", "photo.on.rectangle.angled", "Save to Photos library", .purple)
        case .openURL:
            return ("Open Link", "link", "Open URL in Safari", .blue)
        }
    }
}

/// Service to get universal actions for any screenshot
final class UniversalActionService {
    static let shared = UniversalActionService()

    private init() {}

    /// Get all available actions for a screenshot
    /// Always returns the same list - user chooses what makes sense
    func getAllActions() -> [UniversalAction] {
        return UniversalActionType.allCases.map { type in
            let info = type.displayInfo
            return UniversalAction(
                type: type,
                title: info.title,
                icon: info.icon,
                description: info.description,
                color: info.color
            )
        }
    }

    /// Check if action can be performed (has required data)
    func canPerformAction(_ actionType: UniversalActionType, on screenshot: Screenshot) -> (canPerform: Bool, reason: String?) {
        guard let extractedData = screenshot.extractedData else {
            return (false, "No data has been extracted from this screenshot yet")
        }

        switch actionType {
        case .saveContact:
            // Need at least name OR phone OR email
            let hasContactInfo = extractedData.contactName != nil ||
                                !extractedData.emails.isEmpty ||
                                !extractedData.phoneNumbers.isEmpty
            return (hasContactInfo, hasContactInfo ? nil : "No contact information found on this screenshot")

        case .createNote:
            // Can ALWAYS create note - either with text or just image
            return (true, nil)

        case .addToCalendar:
            // Need event date or event name
            let hasEventInfo = extractedData.eventDate != nil || extractedData.eventName != nil
            return (hasEventInfo, hasEventInfo ? nil : "No event information found on this screenshot")

        case .saveBookmark:
            // Need URL
            let hasURL = !extractedData.urls.isEmpty
            return (hasURL, hasURL ? nil : "No URL found on this screenshot")

        case .openMap:
            // Need address
            let hasAddress = !extractedData.addresses.isEmpty || extractedData.eventLocation != nil
            return (hasAddress, hasAddress ? nil : "No address found on this screenshot")

        case .makeCall:
            // Need phone number
            let hasPhone = !extractedData.phoneNumbers.isEmpty || extractedData.contactPhone != nil
            return (hasPhone, hasPhone ? nil : "No phone number found on this screenshot")

        case .sendEmail:
            // Need email
            let hasEmail = !extractedData.emails.isEmpty || extractedData.contactEmail != nil
            return (hasEmail, hasEmail ? nil : "No email address found on this screenshot")

        case .copyText:
            // Need text
            let hasText = extractedData.fullText != nil && !extractedData.fullText!.isEmpty
            return (hasText, hasText ? nil : "No text found on this screenshot")

        case .shareImage, .saveToPhotos:
            // Always available - has image
            return (true, nil)

        case .openURL:
            // Need URL
            let hasURL = !extractedData.urls.isEmpty
            return (hasURL, hasURL ? nil : "No URL found on this screenshot")
        }
    }
}
