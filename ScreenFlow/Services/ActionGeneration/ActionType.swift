//
//  ActionType.swift
//  ScreenFlow
//
//  Enumeration of available smart action types
//

import Foundation

/// Types of smart actions that can be performed on screenshots
enum ActionType: String, CaseIterable {
    case calendar = "calendar"
    case contact = "contact"
    case map = "map"
    case link = "link"
    case call = "call"
    case email = "email"
    case copy = "copy"
    case note = "note"
    case share = "share"

    /// SF Symbol icon name for this action type
    var iconName: String {
        switch self {
        case .calendar: return "calendar.badge.plus"
        case .contact: return "person.crop.circle.badge.plus"
        case .map: return "map.fill"
        case .link: return "link"
        case .call: return "phone.fill"
        case .email: return "envelope.fill"
        case .copy: return "doc.on.doc"
        case .note: return "note.text"
        case .share: return "square.and.arrow.up"
        }
    }

    /// Default priority for this action type (lower = higher priority)
    var defaultPriority: Int {
        switch self {
        case .calendar: return 1
        case .contact: return 2
        case .map: return 3
        case .link: return 4
        case .call: return 5
        case .email: return 6
        case .copy: return 7
        case .note: return 8
        case .share: return 10
        }
    }
}
