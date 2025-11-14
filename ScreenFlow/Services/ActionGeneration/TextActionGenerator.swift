//
//  TextActionGenerator.swift
//  ScreenFlow
//
//  Generates text-based actions (copy, note) from extracted data
//

import Foundation

/// Generates text manipulation actions
struct TextActionGenerator {
    /// Generate copy text action
    static func generateCopyAction(from data: ExtractedData) -> SmartAction? {
        guard let text = data.fullText, !text.isEmpty, text.count >= 10 else {
            return nil
        }

        let title = "Copy Text"

        let actionData = ActionDataEncoder.encodeString(text)

        return SmartAction(
            actionType: ActionType.copy.rawValue,
            actionTitle: title,
            actionIcon: ActionType.copy.iconName,
            actionData: actionData,
            priority: ActionType.copy.defaultPriority
        )
    }

    /// Generate create note action
    static func generateNoteAction(from data: ExtractedData) -> SmartAction? {
        guard let text = data.fullText, !text.isEmpty, text.count >= 20 else {
            return nil
        }

        let title = "Create Note"

        let actionData = ActionDataEncoder.encodeString(text)

        return SmartAction(
            actionType: ActionType.note.rawValue,
            actionTitle: title,
            actionIcon: ActionType.note.iconName,
            actionData: actionData,
            priority: ActionType.note.defaultPriority
        )
    }

    /// Generate share action (always available)
    static func generateShareAction() -> SmartAction {
        return SmartAction(
            actionType: ActionType.share.rawValue,
            actionTitle: "Share",
            actionIcon: ActionType.share.iconName,
            actionData: "{}",
            priority: ActionType.share.defaultPriority
        )
    }
}
