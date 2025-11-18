//
//  CalendarActionHelper.swift
//  ScreenFlow
//
//  Helper for calendar-related actions using ActionExecutor
//

import Foundation

/// Helper for creating calendar events from screenshots
@MainActor
struct CalendarActionHelper {

    /// Result of calendar action
    enum Result {
        case success(title: String, message: String)
        case failure(title: String, message: String)
    }

    /// Add event to calendar from screenshot using ActionExecutor
    static func addToCalendar(from screenshot: Screenshot) async -> Result {
        guard let extracted = screenshot.extractedData else {
            return .failure(title: "No Data Available", message: "This screenshot hasn't been analyzed yet")
        }

        guard extracted.eventName != nil || extracted.eventDate != nil else {
            return .failure(title: "No Event Information", message: "No event details found on this screenshot")
        }

        // Create SmartAction
        let action = SmartActionFactory.createCalendarAction(from: extracted)

        // Execute using ActionExecutor
        let success = await ActionExecutor.shared.execute(action)

        if success {
            return .success(title: "Event Created", message: "Event added to calendar successfully")
        } else {
            return .failure(title: "Failed to Add Event", message: "Could not add event to calendar")
        }
    }
}
