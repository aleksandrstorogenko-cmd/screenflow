//
//  CalendarActionGenerator.swift
//  ScreenFlow
//
//  Generates calendar/event actions from extracted data
//

import Foundation

/// Generates calendar event actions
struct CalendarActionGenerator {
    /// Generate calendar action if event data is available
    static func generate(from data: ExtractedData) -> SmartAction? {
        // Must have at least a date and either name or location
        guard let startDate = data.eventDate else { return nil }
        guard data.eventName != nil || data.eventLocation != nil else { return nil }

        let title: String
        if let eventName = data.eventName {
            title = "Add to Calendar: \(eventName)"
        } else if let location = data.eventLocation {
            title = "Add Event at \(location)"
        } else {
            title = "Add to Calendar"
        }

        let actionData = ActionDataEncoder.encodeEventData(
            name: data.eventName,
            startDate: startDate,
            endDate: data.eventEndDate,
            location: data.eventLocation,
            description: data.eventDescription
        )

        return SmartAction(
            actionType: ActionType.calendar.rawValue,
            actionTitle: title,
            actionIcon: ActionType.calendar.iconName,
            actionData: actionData,
            priority: ActionType.calendar.defaultPriority
        )
    }
}
