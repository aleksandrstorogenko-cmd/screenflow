//
//  ContactActionGenerator.swift
//  ScreenFlow
//
//  Generates contact actions from extracted data
//

import Foundation

/// Generates add-to-contacts actions
struct ContactActionGenerator {
    /// Generate contact action if contact data is available
    static func generate(from data: ExtractedData) -> SmartAction? {
        // Must have a name and at least one contact method
        guard let name = data.contactName else { return nil }
        guard data.contactPhone != nil || data.contactEmail != nil else { return nil }

        let title = "Add \(name) to Contacts"

        let actionData = ActionDataEncoder.encodeContactData(
            name: name,
            company: data.contactCompany,
            jobTitle: data.contactJobTitle,
            phone: data.contactPhone,
            email: data.contactEmail,
            address: data.contactAddress
        )

        return SmartAction(
            actionType: ActionType.contact.rawValue,
            actionTitle: title,
            actionIcon: ActionType.contact.iconName,
            actionData: actionData,
            priority: ActionType.contact.defaultPriority
        )
    }
}
