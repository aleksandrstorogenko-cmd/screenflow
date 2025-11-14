//
//  MapActionGenerator.swift
//  ScreenFlow
//
//  Generates map/location actions from extracted data
//

import Foundation

/// Generates map and location actions
struct MapActionGenerator {
    /// Generate map action if address or location is available
    static func generate(from data: ExtractedData) -> SmartAction? {
        // Try to find an address from either addresses or event location
        let address: String?

        if !data.addresses.isEmpty {
            address = data.addresses.first
        } else if let eventLocation = data.eventLocation {
            address = eventLocation
        } else {
            return nil
        }

        guard let finalAddress = address, !finalAddress.isEmpty else { return nil }

        // Create shorter title if address is long
        let displayAddress = finalAddress.count > 30
            ? String(finalAddress.prefix(30)) + "..."
            : finalAddress

        let title = "Show on Map: \(displayAddress)"

        let actionData = ActionDataEncoder.encodeString(finalAddress)

        return SmartAction(
            actionType: ActionType.map.rawValue,
            actionTitle: title,
            actionIcon: ActionType.map.iconName,
            actionData: actionData,
            priority: ActionType.map.defaultPriority
        )
    }
}
