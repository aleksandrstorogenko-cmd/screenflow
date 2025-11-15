//
//  SmartActionFactory.swift
//  ScreenFlow
//
//  Factory for creating temporary SmartAction objects for execution
//

import Foundation

/// Factory for creating temporary SmartAction objects
struct SmartActionFactory {

    /// Create a calendar action
    static func createCalendarAction(from extracted: ExtractedData) -> SmartAction {
        let actionData = ActionDataEncoder.encodeEventData(
            name: extracted.eventName,
            startDate: extracted.eventDate,
            endDate: extracted.eventEndDate,
            location: extracted.eventLocation,
            description: extracted.eventDescription
        )

        return SmartAction(
            actionType: ActionType.calendar.rawValue,
            actionTitle: "Add to Calendar",
            actionIcon: ActionType.calendar.iconName,
            actionData: actionData,
            priority: ActionType.calendar.defaultPriority
        )
    }

    /// Create a contact action
    static func createContactAction(from extracted: ExtractedData) -> SmartAction {
        let actionData = ActionDataEncoder.encodeContactData(
            name: extracted.contactName,
            company: extracted.contactCompany,
            jobTitle: extracted.contactJobTitle,
            phone: extracted.contactPhone ?? extracted.phoneNumbers.first,
            email: extracted.contactEmail ?? extracted.emails.first,
            address: extracted.contactAddress
        )

        return SmartAction(
            actionType: ActionType.contact.rawValue,
            actionTitle: "Add to Contacts",
            actionIcon: ActionType.contact.iconName,
            actionData: actionData,
            priority: ActionType.contact.defaultPriority
        )
    }

    /// Create a map action
    static func createMapAction(address: String) -> SmartAction {
        let actionData = ActionDataEncoder.encodeString(address)

        return SmartAction(
            actionType: ActionType.map.rawValue,
            actionTitle: "Open in Maps",
            actionIcon: ActionType.map.iconName,
            actionData: actionData,
            priority: ActionType.map.defaultPriority
        )
    }

    /// Create a link action
    static func createLinkAction(url: String) -> SmartAction {
        let actionData = ActionDataEncoder.encodeString(url)

        return SmartAction(
            actionType: ActionType.link.rawValue,
            actionTitle: "Open Link",
            actionIcon: ActionType.link.iconName,
            actionData: actionData,
            priority: ActionType.link.defaultPriority
        )
    }

    /// Create a call action
    static func createCallAction(phoneNumber: String) -> SmartAction {
        let actionData = ActionDataEncoder.encodeString(phoneNumber)

        return SmartAction(
            actionType: ActionType.call.rawValue,
            actionTitle: "Call",
            actionIcon: ActionType.call.iconName,
            actionData: actionData,
            priority: ActionType.call.defaultPriority
        )
    }

    /// Create an email action
    static func createEmailAction(email: String) -> SmartAction {
        let actionData = ActionDataEncoder.encodeString(email)

        return SmartAction(
            actionType: ActionType.email.rawValue,
            actionTitle: "Send Email",
            actionIcon: ActionType.email.iconName,
            actionData: actionData,
            priority: ActionType.email.defaultPriority
        )
    }

    /// Create a copy text action
    static func createCopyAction(text: String) -> SmartAction {
        let actionData = ActionDataEncoder.encodeString(text)

        return SmartAction(
            actionType: ActionType.copy.rawValue,
            actionTitle: "Copy Text",
            actionIcon: ActionType.copy.iconName,
            actionData: actionData,
            priority: ActionType.copy.defaultPriority
        )
    }

    /// Create a note action
    static func createNoteAction(text: String) -> SmartAction {
        let actionData = ActionDataEncoder.encodeString(text)

        return SmartAction(
            actionType: ActionType.note.rawValue,
            actionTitle: "Create Note",
            actionIcon: ActionType.note.iconName,
            actionData: actionData,
            priority: ActionType.note.defaultPriority
        )
    }

    /// Create a share action
    static func createShareAction() -> SmartAction {
        return SmartAction(
            actionType: ActionType.share.rawValue,
            actionTitle: "Share",
            actionIcon: ActionType.share.iconName,
            actionData: "{}",
            priority: ActionType.share.defaultPriority
        )
    }
}
