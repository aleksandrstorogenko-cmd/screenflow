//
//  CommunicationActionGenerator.swift
//  ScreenFlow
//
//  Generates communication actions (link, call, email) from extracted data
//

import Foundation

/// Generates link, call, and email actions
struct CommunicationActionGenerator {
    /// Generate link actions for URLs
    static func generateLinkActions(from data: ExtractedData) -> [SmartAction] {
        guard !data.urls.isEmpty else { return [] }

        return data.urls.prefix(3).compactMap { urlString in
            guard let url = URL(string: urlString) else { return nil }

            let displayURL = url.host ?? urlString
            let title = "Open: \(displayURL)"

            let actionData = ActionDataEncoder.encodeString(urlString)

            return SmartAction(
                actionType: ActionType.link.rawValue,
                actionTitle: title,
                actionIcon: ActionType.link.iconName,
                actionData: actionData,
                priority: ActionType.link.defaultPriority
            )
        }
    }

    /// Generate call action for phone numbers
    static func generateCallAction(from data: ExtractedData) -> SmartAction? {
        guard !data.phoneNumbers.isEmpty else { return nil }

        let phoneNumber = data.phoneNumbers.first!
        let title = "Call \(phoneNumber)"

        let actionData = ActionDataEncoder.encodeString(phoneNumber)

        return SmartAction(
            actionType: ActionType.call.rawValue,
            actionTitle: title,
            actionIcon: ActionType.call.iconName,
            actionData: actionData,
            priority: ActionType.call.defaultPriority
        )
    }

    /// Generate email action for email addresses
    static func generateEmailAction(from data: ExtractedData) -> SmartAction? {
        guard !data.emails.isEmpty else { return nil }

        let email = data.emails.first!
        let title = "Email \(email)"

        let actionData = ActionDataEncoder.encodeString(email)

        return SmartAction(
            actionType: ActionType.email.rawValue,
            actionTitle: title,
            actionIcon: ActionType.email.iconName,
            actionData: actionData,
            priority: ActionType.email.defaultPriority
        )
    }
}
