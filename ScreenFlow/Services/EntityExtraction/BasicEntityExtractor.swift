//
//  BasicEntityExtractor.swift
//  ScreenFlow
//
//  Extracts basic entities using NSDataDetector
//

import Foundation

/// Extracts URLs, emails, phone numbers, addresses, and dates from text
final class BasicEntityExtractor {
    /// Extract all basic entities from text using NSDataDetector
    func extract(from text: String) -> BasicEntities {
        var entities = BasicEntities()

        guard !text.isEmpty else { return entities }

        // Create data detector for all types
        let types: NSTextCheckingResult.CheckingType = [
            .link,
            .phoneNumber,
            .address,
            .date
        ]

        guard let detector = try? NSDataDetector(types: types.rawValue) else {
            return entities
        }

        let range = NSRange(text.startIndex..., in: text)
        let matches = detector.matches(in: text, options: [], range: range)

        for match in matches {
            switch match.resultType {
            case .link:
                if let url = match.url {
                    entities.urls.append(url)
                }

            case .phoneNumber:
                if let phoneNumber = match.phoneNumber {
                    entities.phoneNumbers.append(phoneNumber)
                }

            case .address:
                if let address = match.components?[.street] ?? match.components?[.city] {
                    // Construct full address from components
                    let fullAddress = constructAddress(from: match.components)
                    if !fullAddress.isEmpty {
                        entities.addresses.append(fullAddress)
                    }
                }

            case .date:
                if let date = match.date {
                    entities.dates.append(date)
                }

            default:
                break
            }
        }

        // Extract emails using regex (NSDataDetector sometimes misses them)
        entities.emails = extractEmails(from: text)

        return entities
    }

    // MARK: - Private Helpers

    private func constructAddress(from components: [NSTextCheckingKey: String]?) -> String {
        guard let components = components else { return "" }

        var parts: [String] = []

        if let street = components[.street] {
            parts.append(street)
        }
        if let city = components[.city] {
            parts.append(city)
        }
        if let state = components[.state] {
            parts.append(state)
        }
        if let zip = components[.zip] {
            parts.append(zip)
        }
        if let country = components[.country] {
            parts.append(country)
        }

        return parts.joined(separator: ", ")
    }

    private func extractEmails(from text: String) -> [String] {
        let pattern = #"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}"#

        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }

        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, options: [], range: range)

        return matches.compactMap { match in
            guard let range = Range(match.range, in: text) else { return nil }
            return String(text[range])
        }
    }
}
