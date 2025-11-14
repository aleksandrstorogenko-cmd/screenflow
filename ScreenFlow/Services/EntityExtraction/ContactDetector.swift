//
//  ContactDetector.swift
//  ScreenFlow
//
//  Detects contact/business card information from screenshot text
//

import Foundation
import NaturalLanguage

/// Detects contact information by grouping names with nearby contact details
final class ContactDetector {
    // Job title keywords
    private let jobTitleKeywords = [
        "ceo", "cto", "cfo", "director", "manager", "president",
        "vice president", "vp", "engineer", "developer", "designer",
        "consultant", "analyst", "specialist", "coordinator", "assistant",
        "founder", "owner", "partner", "lead", "senior", "junior"
    ]

    /// Detect contact information from text and basic entities
    func detect(from text: String, entities: BasicEntities) -> ContactData? {
        var contact = ContactData()

        // Must have at least a phone or email to be considered a contact
        guard !entities.phoneNumbers.isEmpty || !entities.emails.isEmpty else {
            return nil
        }

        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        // Extract person names using NLTagger
        let names = extractPersonNames(from: text)

        // Use the first found name
        contact.name = names.first

        // Extract company name (usually near the top or after job title)
        contact.company = extractCompanyName(from: lines)

        // Extract job title
        contact.jobTitle = extractJobTitle(from: lines)

        // Use first phone and email
        contact.phone = entities.phoneNumbers.first
        contact.email = entities.emails.first
        contact.address = entities.addresses.first

        // Only return if we have a valid contact
        return contact.isValid ? contact : nil
    }

    // MARK: - Private Helpers

    private func extractPersonNames(from text: String) -> [String] {
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text

        var names: [String] = []

        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                             unit: .word,
                             scheme: .nameType,
                             options: [.omitWhitespace, .omitPunctuation]) { tag, range in
            if tag == .personalName {
                let name = String(text[range])
                // Only add if it looks like a reasonable name (2-50 chars, has letters)
                if name.count >= 2 && name.count <= 50 && name.contains(where: { $0.isLetter }) {
                    names.append(name)
                }
            }
            return true
        }

        // If NLTagger didn't find names, try pattern matching
        if names.isEmpty {
            names = extractNamesByPattern(from: text)
        }

        return names
    }

    private func extractNamesByPattern(from text: String) -> [String] {
        // Pattern: Two capitalized words (common name format)
        let pattern = #"\b[A-Z][a-z]+\s+[A-Z][a-z]+\b"#

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

    private func extractCompanyName(from lines: [String]) -> String? {
        // Company name is usually one of the first few lines
        // and might contain words like Inc, LLC, Corp, Ltd, Company
        let companyIndicators = ["inc", "llc", "corp", "ltd", "limited", "company", "co."]

        for line in lines.prefix(5) {
            let lowerLine = line.lowercased()

            // Check if line contains company indicators
            for indicator in companyIndicators {
                if lowerLine.contains(indicator) {
                    return line
                }
            }

            // Company names are often short lines (10-50 chars) in all caps or title case
            if line.count >= 10 && line.count <= 50 {
                let uppercaseCount = line.filter { $0.isUppercase }.count
                let totalLetters = line.filter { $0.isLetter }.count

                // If mostly uppercase, might be company name
                if totalLetters > 0 && Double(uppercaseCount) / Double(totalLetters) > 0.5 {
                    return line
                }
            }
        }

        return nil
    }

    private func extractJobTitle(from lines: [String]) -> String? {
        for line in lines {
            let lowerLine = line.lowercased()

            // Check if line contains job title keywords
            for keyword in jobTitleKeywords {
                if lowerLine.contains(keyword) {
                    // Return the line if it's a reasonable length
                    if line.count >= 3 && line.count <= 60 {
                        return line
                    }
                }
            }
        }

        return nil
    }
}
