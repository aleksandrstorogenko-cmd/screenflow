//
//  SmartAction.swift
//  ScreenFlow
//
//  SwiftData model for storing smart actions generated from screenshot content
//

import Foundation
import SwiftData

/// Represents a context-aware action that can be performed on a screenshot
@Model
final class SmartAction {
    // MARK: - Relationships

    /// Parent screenshot
    var screenshot: Screenshot?

    // MARK: - Action Data

    /// Action type identifier
    /// Possible values: "calendar", "contact", "map", "link", "call", "email", "copy", "note", "share"
    var actionType: String

    /// Human-readable action title
    var actionTitle: String

    /// SF Symbol icon name
    var actionIcon: String

    /// Action-specific data encoded as JSON string
    var actionData: String

    /// Display priority (lower number = higher priority)
    var priority: Int

    /// Whether this action is currently enabled
    var isEnabled: Bool

    // MARK: - Initialization

    init(
        actionType: String,
        actionTitle: String,
        actionIcon: String,
        actionData: String,
        priority: Int
    ) {
        self.actionType = actionType
        self.actionTitle = actionTitle
        self.actionIcon = actionIcon
        self.actionData = actionData
        self.priority = priority
        self.isEnabled = true
    }
}
