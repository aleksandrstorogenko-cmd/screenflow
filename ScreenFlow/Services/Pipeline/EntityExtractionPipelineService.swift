//
//  EntityExtractionPipelineService.swift
//  ScreenFlow
//
//  Service for extracting entities from text in the processing pipeline
//

import Foundation
import NaturalLanguage

/// Service for extracting structured entities from text
final class EntityExtractionPipelineService: EntityExtractionServiceProtocol {

    // MARK: - Properties

    static let shared = EntityExtractionPipelineService()

    private init() {}

    // MARK: - EntityExtractionServiceProtocol

    /// Extract entities from raw text
    ///
    /// - Parameters:
    ///   - rawText: Plain OCR text
    ///   - markdown: Optional Markdown-formatted text (for structure hints)
    /// - Returns: Extracted entities and normalized text
    /// - Throws: Processing errors
    func extractEntities(from rawText: String, markdown: String?) async throws -> EntityExtractionResult {
        // Normalize text (trim whitespace, remove excessive newlines)
        let normalizedText = normalizeText(rawText)

        // Detect language
        let detectedLanguage = detectLanguage(of: normalizedText)

        // Extract entities
        var entities: [ExtractedEntity] = []

        // Extract basic entities (URLs, emails, phones)
        entities.append(contentsOf: extractBasicEntities(from: normalizedText))

        // Extract dates
        entities.append(contentsOf: extractDates(from: normalizedText))

        // Extract addresses (pattern-based)
        entities.append(contentsOf: extractAddresses(from: normalizedText))

        // If markdown is available, use it for better context
        if let markdown = markdown {
            entities.append(contentsOf: extractStructuredEntities(from: markdown))
        }

        return EntityExtractionResult(
            entities: entities,
            normalizedText: normalizedText,
            detectedLanguage: detectedLanguage
        )
    }

    // MARK: - Private Methods

    /// Normalize text by trimming and cleaning up whitespace
    private func normalizeText(_ text: String) -> String {
        var normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Replace multiple newlines with double newline
        normalized = normalized.replacingOccurrences(
            of: #"\n{3,}"#,
            with: "\n\n",
            options: .regularExpression
        )

        return normalized
    }

    /// Detect language of text
    private func detectLanguage(of text: String) -> String? {
        guard !text.isEmpty else { return nil }

        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)

        return recognizer.dominantLanguage?.rawValue
    }

    /// Extract basic entities (URLs, emails, phone numbers)
    private func extractBasicEntities(from text: String) -> [ExtractedEntity] {
        var entities: [ExtractedEntity] = []

        // Use NSDataDetector for URLs, emails, phone numbers
        let types: NSTextCheckingResult.CheckingType = [.link, .phoneNumber]
        guard let detector = try? NSDataDetector(types: types.rawValue) else {
            return entities
        }

        let nsString = text as NSString
        let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))

        for match in matches {
            switch match.resultType {
            case .link:
                if let url = match.url {
                    entities.append(ExtractedEntity(
                        kind: .url,
                        value: url.absoluteString,
                        range: match.range,
                        metadata: nil
                    ))
                }

            case .phoneNumber:
                if let phone = match.phoneNumber {
                    entities.append(ExtractedEntity(
                        kind: .phone,
                        value: phone,
                        range: match.range,
                        metadata: nil
                    ))
                }

            default:
                break
            }
        }

        // Extract emails with regex (NSDataDetector sometimes misses them)
        if let emailRegex = try? NSRegularExpression(
            pattern: #"[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}"#,
            options: [.caseInsensitive]
        ) {
            let emailMatches = emailRegex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
            for match in emailMatches {
                let email = nsString.substring(with: match.range)
                // Avoid duplicates
                if !entities.contains(where: { $0.kind == .email && $0.value == email }) {
                    entities.append(ExtractedEntity(
                        kind: .email,
                        value: email,
                        range: match.range,
                        metadata: nil
                    ))
                }
            }
        }

        return entities
    }

    /// Extract dates from text
    private func extractDates(from text: String) -> [ExtractedEntity] {
        var entities: [ExtractedEntity] = []

        let types: NSTextCheckingResult.CheckingType = [.date]
        guard let detector = try? NSDataDetector(types: types.rawValue) else {
            return entities
        }

        let nsString = text as NSString
        let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))

        for match in matches {
            if let date = match.date {
                let formatter = ISO8601DateFormatter()
                entities.append(ExtractedEntity(
                    kind: .date,
                    value: formatter.string(from: date),
                    range: match.range,
                    metadata: ["rawText": nsString.substring(with: match.range)]
                ))
            }
        }

        return entities
    }

    /// Extract addresses using pattern matching
    private func extractAddresses(from text: String) -> [ExtractedEntity] {
        var entities: [ExtractedEntity] = []

        let types: NSTextCheckingResult.CheckingType = [.address]
        guard let detector = try? NSDataDetector(types: types.rawValue) else {
            return entities
        }

        let nsString = text as NSString
        let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))

        for match in matches {
            if let components = match.addressComponents {
                let addressParts = [
                    components[.street],
                    components[.city],
                    components[.state],
                    components[.zip]
                ].compactMap { $0 }

                if !addressParts.isEmpty {
                    entities.append(ExtractedEntity(
                        kind: .address,
                        value: addressParts.joined(separator: ", "),
                        range: match.range,
                        metadata: nil
                    ))
                }
            }
        }

        return entities
    }

    /// Extract structured entities from Markdown (headings, lists, etc.)
    private func extractStructuredEntities(from markdown: String) -> [ExtractedEntity] {
        var entities: [ExtractedEntity] = []

        // Extract headings as potential organization/event names
        let headingPattern = #"^#+\s+(.+)$"#
        if let headingRegex = try? NSRegularExpression(pattern: headingPattern, options: [.anchorsMatchLines]) {
            let nsString = markdown as NSString
            let matches = headingRegex.matches(
                in: markdown,
                options: [],
                range: NSRange(location: 0, length: nsString.length)
            )

            for match in matches {
                if match.numberOfRanges > 1 {
                    let headingText = nsString.substring(with: match.range(at: 1))
                    // Classify based on content
                    let kind: ExtractedEntityKind = headingText.contains(where: { $0.isNumber }) ? .event : .organization

                    entities.append(ExtractedEntity(
                        kind: kind,
                        value: headingText,
                        range: match.range(at: 1),
                        metadata: ["source": "markdown_heading"]
                    ))
                }
            }
        }

        return entities
    }
}
