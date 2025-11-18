//
//  ExtractedDataAdapter.swift
//  ScreenFlow
//
//  Adapter for converting pipeline output to SwiftData models
//

import Foundation

/// Adapter for converting ProcessedScreenshotData to SwiftData ExtractedData
final class ExtractedDataAdapter {

    // MARK: - Dependencies

    private static let eventDetector = EventDetector()
    private static let contactDetector = ContactDetector()

    // MARK: - Public Methods

    /// Convert ProcessedScreenshotData to SwiftData ExtractedData model
    ///
    /// - Parameter processedData: Output from the processing pipeline
    /// - Returns: SwiftData ExtractedData model ready for persistence
    static func toSwiftDataModel(_ processedData: ProcessedScreenshotData) -> ExtractedData {
        let extractedData = ExtractedData()

        // Store text content
        extractedData.fullText = processedData.rawText
        extractedData.formattedText = processedData.formattedText
        extractedData.textLanguage = processedData.detectedLanguage

        // Collect basic entities first
        var urls: [URL] = []
        var emails: [String] = []
        var phones: [String] = []
        var addresses: [String] = []
        var dates: [Date] = []

        // Extract and categorize entities
        for entity in processedData.entities {
            switch entity.kind {
            case .url:
                if let url = URL(string: entity.value), !extractedData.urls.contains(entity.value) {
                    extractedData.urls.append(entity.value)
                    urls.append(url)
                }

            case .email:
                if !extractedData.emails.contains(entity.value) {
                    extractedData.emails.append(entity.value)
                    emails.append(entity.value)
                }

            case .phone:
                if !extractedData.phoneNumbers.contains(entity.value) {
                    extractedData.phoneNumbers.append(entity.value)
                    phones.append(entity.value)
                }

            case .address:
                if !extractedData.addresses.contains(entity.value) {
                    extractedData.addresses.append(entity.value)
                    addresses.append(entity.value)
                }

            case .date:
                // Parse ISO8601 date
                if (entity.metadata?["rawText"]) != nil {
                    let formatter = ISO8601DateFormatter()
                    if let date = formatter.date(from: entity.value) {
                        dates.append(date)
                    }
                }

            case .event, .person, .organization, .location, .custom:
                // These will be handled by specialized detectors below
                break
            }
        }

        // Use specialized detectors for event and contact data
        // This ensures proper validation and reduces false positives
        let basicEntities = BasicEntities(
            urls: urls,
            emails: emails,
            phoneNumbers: phones,
            addresses: addresses,
            dates: dates
        )

        // Detect events with proper validation
        if let event = eventDetector.detect(
            from: processedData.rawText,
            entities: basicEntities,
            sceneClassifications: processedData.ocrBlocks.isEmpty ? [] : []
        ) {
            extractedData.eventName = event.name
            extractedData.eventDate = event.startDate
            extractedData.eventEndDate = event.endDate
            extractedData.eventLocation = event.location
            extractedData.eventDescription = event.description
        }

        // Detect contacts with proper validation
        if let contact = contactDetector.detect(
            from: processedData.rawText,
            entities: basicEntities
        ) {
            extractedData.contactName = contact.name
            extractedData.contactCompany = contact.company
            extractedData.contactJobTitle = contact.jobTitle
            extractedData.contactPhone = contact.phone
            extractedData.contactEmail = contact.email
            extractedData.contactAddress = contact.address
        }

        // Set confidence based on entity richness
        extractedData.confidence = calculateConfidence(for: processedData)

        return extractedData
    }

    // MARK: - Private Methods

    /// Calculate confidence score based on extracted data richness
    private static func calculateConfidence(for data: ProcessedScreenshotData) -> Double {
        var totalScore = 0.0
        var maxScore = 0.0

        // Text content
        maxScore += 0.2
        if !data.rawText.isEmpty {
            totalScore += 0.2
        }

        // Markdown formatting
        maxScore += 0.2
        if !data.formattedText.isEmpty && data.formattedText != data.rawText {
            totalScore += 0.2
        }

        // Entity presence
        maxScore += 0.3
        if !data.entities.isEmpty {
            totalScore += 0.3
        }

        // Language detection
        maxScore += 0.1
        if data.detectedLanguage != nil {
            totalScore += 0.1
        }

        // OCR quality (based on block count)
        maxScore += 0.2
        if !data.ocrBlocks.isEmpty {
            totalScore += 0.2
        }

        return totalScore / maxScore
    }
}

