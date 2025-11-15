//
//  EventDetector.swift
//  ScreenFlow
//
//  Detects event information from screenshot text
//

import Foundation

/// Detects events by combining dates, locations, and event keywords
final class EventDetector {
    // Event-related keywords
    private let eventKeywords = [
        "concert", "meeting", "conference", "show", "performance",
        "appointment", "reservation", "flight", "game", "match",
        "class", "lecture", "seminar", "workshop", "webinar",
        "party", "celebration", "wedding", "birthday", "event"
    ]

    // Location indicator words
    private let locationIndicators = [
        "at", "in", "venue", "location", "place", "hall", "center",
        "stadium", "arena", "theatre", "theater", "auditorium",
        "room", "building", "address"
    ]

    /// Detect event information from text and basic entities
    func detect(from text: String, entities: BasicEntities, sceneClassifications: [(identifier: String, confidence: Float)] = []) -> EventData? {
        var event = EventData()

        // Must have at least one date
        guard !entities.dates.isEmpty else { return nil }

        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        // Check if this looks like a social media post or chat message
        let isSocialMedia = isSocialMediaContext(sceneClassifications: sceneClassifications, text: text, lines: lines)

        // Check if text contains event keywords
        let lowerText = text.lowercased()
        let hasEventKeyword = eventKeywords.contains { lowerText.contains($0) }

        // For social media/chat, require strong evidence of an event
        if isSocialMedia {
            // Only proceed if there are explicit event keywords AND multiple dates
            guard hasEventKeyword && entities.dates.count >= 2 else {
                return nil
            }
        } else {
            // For other contexts, use the original logic
            guard hasEventKeyword || entities.dates.count >= 2 else {
                return nil
            }
        }

        // Extract event date (prefer the first date)
        event.startDate = entities.dates.first

        // If multiple dates, second might be end date
        if entities.dates.count >= 2 {
            event.endDate = entities.dates[1]
        }

        // Extract event name (look for prominent text, usually first few lines)
        event.name = extractEventName(from: lines)

        // Extract location
        event.location = extractLocation(from: text, addresses: entities.addresses)

        // Extract description (combine relevant lines)
        event.description = extractDescription(from: lines)

        // Only return if we have a valid event
        return event.isValid ? event : nil
    }

    // MARK: - Private Helpers

    private func extractEventName(from lines: [String]) -> String? {
        // Event name is usually in the first few lines and has reasonable length
        for line in lines.prefix(5) {
            // Skip very short lines (< 3 chars) and very long lines (> 80 chars)
            guard line.count >= 3 && line.count <= 80 else { continue }

            // Skip lines that look like dates or times
            if line.range(of: #"\d{1,2}:\d{2}"#, options: .regularExpression) != nil {
                continue
            }

            // Skip lines that are just numbers
            let alphaCount = line.filter { $0.isLetter }.count
            guard alphaCount >= line.count / 2 else { continue }

            return line
        }

        return nil
    }

    private func extractLocation(from text: String, addresses: [String]) -> String? {
        // If we have an address, use it
        if let address = addresses.first {
            return address
        }

        // Look for location patterns
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        for line in lines {
            let lowerLine = line.lowercased()

            // Check if line contains location indicators
            for indicator in locationIndicators {
                if lowerLine.contains(indicator) {
                    // Extract the part after the indicator
                    if let range = lowerLine.range(of: indicator) {
                        let afterIndicator = String(line[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                        if afterIndicator.count > 3 {
                            return String(afterIndicator.prefix(100))
                        }
                    }
                    return line
                }
            }
        }

        return nil
    }

    private func extractDescription(from lines: [String]) -> String? {
        // Combine lines that look like description text
        let descriptionLines = lines.filter { line in
            line.count > 20 && line.count < 200
        }

        guard !descriptionLines.isEmpty else { return nil }

        return descriptionLines.prefix(3).joined(separator: " ")
    }

    /// Check if the screenshot appears to be from social media or chat
    private func isSocialMediaContext(sceneClassifications: [(identifier: String, confidence: Float)], text: String, lines: [String]) -> Bool {
        // Check scene classifications for social media or chat indicators
        let topScenes = sceneClassifications.prefix(3).map { $0.identifier.lowercased() }
        for scene in topScenes {
            if scene.contains("conversation") || scene.contains("message") ||
               scene.contains("chat") || scene.contains("social") ||
               scene.contains("post") || scene.contains("feed") {
                return true
            }
        }

        // Check for common social media UI patterns
        let lowerText = text.lowercased()
        let socialMediaIndicators = [
            "views", "likes", "comments", "share", "retweet", "reply",
            "follow", "followers", "following", "subscribe", "subscribers",
            "ago", "min ago", "hour ago", "day ago", "week ago",
            "posted", "shared", "retweeted", "commented"
        ]

        var indicatorCount = 0
        for indicator in socialMediaIndicators {
            if lowerText.contains(indicator) {
                indicatorCount += 1
            }
        }

        // If we find multiple social media indicators, it's likely social media
        if indicatorCount >= 2 {
            return true
        }

        // Check for typical social media post structure:
        // Short date/time at the top (like "27/1/25" or "2h ago") followed by content
        if let firstLine = lines.first {
            let datePatterns = [
                #"\d{1,2}/\d{1,2}/\d{2,4}"#,  // 27/1/25
                #"\d{1,2}[hmd]\s*ago"#,         // 2h ago, 5m ago, 3d ago
                #"(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s+\d{1,2}"#  // Jan 27
            ]

            for pattern in datePatterns {
                if firstLine.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil {
                    // If the first line is very short and contains a date, it's likely a timestamp
                    if firstLine.count < 20 {
                        return true
                    }
                }
            }
        }

        return false
    }
}
