//
//  CalendarActionHandler.swift
//  ScreenFlow
//
//  Handles calendar/event actions using EventKit
//

import Foundation
import EventKit
import UIKit

/// Handles calendar event actions
@MainActor
final class CalendarActionHandler {
    private let eventStore = EKEventStore()

    /// Execute calendar action
    func execute(_ action: SmartAction) async -> Bool {
        // Request calendar access
        let granted = await requestCalendarAccess()
        guard granted else {
            print("Calendar access denied")
            return false
        }

        // Decode event data
        guard let eventData = ActionDataDecoder.decodeEventData(action.actionData) else {
            print("Failed to decode event data")
            return false
        }

        // Create event
        let event = EKEvent(eventStore: eventStore)
        event.title = eventData.name ?? "Event"
        event.startDate = eventData.startDate ?? Date()
        event.endDate = eventData.endDate ?? event.startDate.addingTimeInterval(3600) // 1 hour default
        event.location = eventData.location
        event.notes = eventData.description
        event.calendar = eventStore.defaultCalendarForNewEvents

        // Save event
        do {
            try eventStore.save(event, span: .thisEvent)
            print("Event saved successfully: \(event.title ?? "Unknown")")
            return true
        } catch {
            print("Failed to save event: \(error)")
            return false
        }
    }

    // MARK: - Private Helpers

    private func requestCalendarAccess() async -> Bool {
        if #available(iOS 17.0, *) {
            do {
                return try await eventStore.requestFullAccessToEvents()
            } catch {
                print("Calendar access request failed: \(error)")
                return false
            }
        } else {
            return await withCheckedContinuation { continuation in
                eventStore.requestAccess(to: .event) { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
        }
    }
}
