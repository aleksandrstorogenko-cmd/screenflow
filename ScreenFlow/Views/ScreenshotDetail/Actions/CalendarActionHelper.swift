//
//  CalendarActionHelper.swift
//  ScreenFlow
//
//  Helper for calendar-related actions
//

import Foundation
import EventKit

/// Helper for creating calendar events from screenshots
/// TODO: Refactor to use ActionExecutor service instead of inline implementation
struct CalendarActionHelper {

    /// Result of calendar action
    enum Result {
        case success(title: String, message: String)
        case failure(title: String, message: String)
    }

    /// Add event to calendar from screenshot
    static func addToCalendar(from screenshot: Screenshot) async -> Result {
        guard let extracted = screenshot.extractedData else {
            return .failure(title: "No Data Available", message: "This screenshot hasn't been analyzed yet")
        }

        guard extracted.eventName != nil || extracted.eventDate != nil else {
            return .failure(title: "No Event Information", message: "No event details found on this screenshot")
        }

        let eventStore = EKEventStore()
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            if granted {
                let event = EKEvent(eventStore: eventStore)
                event.title = extracted.eventName ?? "Event from Screenshot"
                event.startDate = extracted.eventDate ?? Date()
                event.endDate = extracted.eventEndDate ?? event.startDate.addingTimeInterval(3600)
                event.location = extracted.eventLocation
                event.notes = extracted.eventDescription
                event.calendar = eventStore.defaultCalendarForNewEvents

                try eventStore.save(event, span: .thisEvent)

                return .success(title: "Event Created", message: "Event added to calendar successfully")
            } else {
                return .failure(title: "Permission Denied", message: "Calendar access is required")
            }
        } catch {
            return .failure(title: "Error", message: "Failed to create event: \(error.localizedDescription)")
        }
    }
}
