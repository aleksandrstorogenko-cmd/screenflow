//
//  ExtractedDataAdapter.swift
//  ScreenFlow
//
//  Adapter for converting pipeline output to SwiftData models
//

import Foundation

/// Adapter for converting ProcessedScreenshotData to SwiftData ExtractedData
final class ExtractedDataAdapter {

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

        // Extract and categorize entities
        for entity in processedData.entities {
            switch entity.kind {
            case .url:
                if !extractedData.urls.contains(entity.value) {
                    extractedData.urls.append(entity.value)
                }

            case .email:
                if !extractedData.emails.contains(entity.value) {
                    extractedData.emails.append(entity.value)
                }

            case .phone:
                if !extractedData.phoneNumbers.contains(entity.value) {
                    extractedData.phoneNumbers.append(entity.value)
                }

            case .address:
                if !extractedData.addresses.contains(entity.value) {
                    extractedData.addresses.append(entity.value)
                }

            case .date:
                // Store date entity metadata
                if let rawText = entity.metadata?["rawText"] {
                    // Could parse and store in eventDate if needed
                    _ = rawText
                }

            case .event:
                // First event entity becomes the event name
                if extractedData.eventName == nil {
                    extractedData.eventName = entity.value
                }

            case .person:
                // First person entity becomes contact name
                if extractedData.contactName == nil {
                    extractedData.contactName = entity.value
                }

            case .organization:
                // First organization entity becomes contact company
                if extractedData.contactCompany == nil {
                    extractedData.contactCompany = entity.value
                }

            case .location:
                // First location becomes event location
                if extractedData.eventLocation == nil {
                    extractedData.eventLocation = entity.value
                }

            case .custom:
                // Handle custom entity types
                break
            }
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

        return maxScore > 0 ? totalScore / maxScore : 0.0
    }
}
