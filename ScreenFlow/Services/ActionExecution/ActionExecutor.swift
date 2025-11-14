//
//  ActionExecutor.swift
//  ScreenFlow
//
//  Main service for executing smart actions
//

import Foundation

/// Service for executing smart actions
@MainActor
final class ActionExecutor {
    static let shared = ActionExecutor()

    // Action handlers
    private let calendarHandler = CalendarActionHandler()
    private let contactHandler = ContactActionHandler()
    private let mapHandler = MapActionHandler()
    private let communicationHandler = CommunicationActionHandler()
    private let textHandler = TextActionHandler()

    private init() {}

    // MARK: - Public API

    /// Execute a smart action
    /// - Parameters:
    ///   - action: The action to execute
    ///   - screenshot: Optional screenshot (needed for share action)
    /// - Returns: Boolean indicating success
    func execute(_ action: SmartAction, screenshot: Screenshot? = nil) async -> Bool {
        guard action.isEnabled else {
            print("Action is disabled: \(action.actionType)")
            return false
        }

        print("Executing action: \(action.actionType) - \(action.actionTitle)")

        switch action.actionType {
        case ActionType.calendar.rawValue:
            return await calendarHandler.execute(action)

        case ActionType.contact.rawValue:
            return await contactHandler.execute(action)

        case ActionType.map.rawValue:
            return await mapHandler.execute(action)

        case ActionType.link.rawValue:
            return await communicationHandler.executeLink(action)

        case ActionType.call.rawValue:
            return await communicationHandler.executeCall(action)

        case ActionType.email.rawValue:
            return await communicationHandler.executeEmail(action)

        case ActionType.copy.rawValue:
            return await textHandler.executeCopy(action)

        case ActionType.note.rawValue:
            return await textHandler.executeNote(action)

        case ActionType.share.rawValue:
            guard let screenshot = screenshot else {
                print("Screenshot required for share action")
                return false
            }
            return await textHandler.executeShare(screenshot: screenshot)

        default:
            print("Unknown action type: \(action.actionType)")
            return false
        }
    }
}
