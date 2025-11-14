//
//  EventData.swift
//  ScreenFlow
//
//  Structure for holding extracted event information
//

import Foundation

/// Holds extracted event information from screenshot text
struct EventData {
    var name: String?
    var startDate: Date?
    var endDate: Date?
    var location: String?
    var description: String?

    var isValid: Bool {
        // Must have at least a date and either name or location
        guard startDate != nil else { return false }
        return name != nil || location != nil
    }

    var confidence: Double {
        var score = 0.0

        if startDate != nil { score += 0.3 }
        if name != nil { score += 0.3 }
        if location != nil { score += 0.2 }
        if endDate != nil { score += 0.1 }
        if description != nil { score += 0.1 }

        return score
    }
}
