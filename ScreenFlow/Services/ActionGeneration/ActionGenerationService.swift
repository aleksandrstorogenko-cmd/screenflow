//
//  ActionGenerationService.swift
//  ScreenFlow
//
//  Main service for generating smart actions from extracted data
//

import Foundation

/// Service for generating smart actions based on extracted screenshot data
final class ActionGenerationService {
    static let shared = ActionGenerationService()

    private init() {}

    // MARK: - Public API

    /// Generate all applicable smart actions from extracted data
    func generateActions(from extractedData: ExtractedData) -> [SmartAction] {
        var actions: [SmartAction] = []

        // 1. Calendar/Event action
        if let eventAction = CalendarActionGenerator.generate(from: extractedData) {
            actions.append(eventAction)
        }

        // 2. Contact action
        if let contactAction = ContactActionGenerator.generate(from: extractedData) {
            actions.append(contactAction)
        }

        // 3. Map/Location action
        if let mapAction = MapActionGenerator.generate(from: extractedData) {
            actions.append(mapAction)
        }

        // 4. Link actions (multiple URLs possible)
        let linkActions = CommunicationActionGenerator.generateLinkActions(from: extractedData)
        actions.append(contentsOf: linkActions)

        // 5. Call action
        if let callAction = CommunicationActionGenerator.generateCallAction(from: extractedData) {
            actions.append(callAction)
        }

        // 6. Email action
        if let emailAction = CommunicationActionGenerator.generateEmailAction(from: extractedData) {
            actions.append(emailAction)
        }

        // 7. Copy text action
        if let copyAction = TextActionGenerator.generateCopyAction(from: extractedData) {
            actions.append(copyAction)
        }

        // 8. Create note action
        if let noteAction = TextActionGenerator.generateNoteAction(from: extractedData) {
            actions.append(noteAction)
        }

        // 9. Share action (always available)
        actions.append(TextActionGenerator.generateShareAction())

        // Sort by priority (lower number = higher priority)
        return actions.sorted { $0.priority < $1.priority }
    }
}
