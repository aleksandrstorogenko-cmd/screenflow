//
//  EntityExtractionService.swift
//  ScreenFlow
//
//  Main service for extracting entities from screenshots
//

import Foundation
import Vision
import NaturalLanguage
import CoreGraphics

/// Service for extracting structured data from screenshots
final class EntityExtractionService {
    static let shared = EntityExtractionService()

    private let basicExtractor = BasicEntityExtractor()
    private let eventDetector = EventDetector()
    private let contactDetector = ContactDetector()
    private let objectDetectionService = ObjectDetectionService.shared
    private let textFormatter = TextFormatterService.shared

    private init() {}

    // MARK: - Public API

    /// Extract all entities from screenshot text and image
    func extractEntities(
        from text: String,
        textObservations: [VNRecognizedTextObservation],
        sceneClassifications: [(identifier: String, confidence: Float)],
        cgImage: CGImage?
    ) async -> ExtractedData {
        let extractedData = ExtractedData()

        // Store full text
        extractedData.fullText = text

        // Format text as markdown using Vision observations
        extractedData.formattedText = await textFormatter.formatAsMarkdown(
            text: text,
            observations: textObservations
        )

        // Detect language
        extractedData.textLanguage = detectLanguage(of: text)

        // Extract basic entities
        let basicEntities = basicExtractor.extract(from: text)
        extractedData.urls = basicEntities.urls.map { $0.absoluteString }
        extractedData.emails = basicEntities.emails
        extractedData.phoneNumbers = basicEntities.phoneNumbers
        extractedData.addresses = basicEntities.addresses

        // Try to detect event (pass scene classifications for context)
        if let event = eventDetector.detect(from: text, entities: basicEntities, sceneClassifications: sceneClassifications) {
            extractedData.eventName = event.name
            extractedData.eventDate = event.startDate
            extractedData.eventEndDate = event.endDate
            extractedData.eventLocation = event.location
            extractedData.eventDescription = event.description
        }

        // Try to detect contact
        if let contact = contactDetector.detect(from: text, entities: basicEntities) {
            extractedData.contactName = contact.name
            extractedData.contactCompany = contact.company
            extractedData.contactJobTitle = contact.jobTitle
            extractedData.contactPhone = contact.phone
            extractedData.contactEmail = contact.email
            extractedData.contactAddress = contact.address
        }

        // Detect objects in the image
        if let cgImage = cgImage {
            let objectResults = await objectDetectionService.detectObjects(in: cgImage)

            // Convert results to DetectedObject models
            for result in objectResults {
                let detectedObject = DetectedObject(
                    label: result.label,
                    details: result.attributes?["color"] ?? result.attributes?["type"],
                    confidence: result.confidence
                )
                detectedObject.boundingBox = ObjectDetectionService.boundingBoxToJSON(result.boundingBox)
                detectedObject.extractedData = extractedData
                extractedData.detectedObjects.append(detectedObject)
            }
        }

        // Store scene description
        extractedData.sceneDescription = createSceneDescription(from: sceneClassifications)

        // Calculate confidence
        extractedData.confidence = calculateConfidence(for: extractedData, basicEntities: basicEntities)

        return extractedData
    }

    // MARK: - Private Helpers

    private func detectLanguage(of text: String) -> String? {
        guard !text.isEmpty else { return nil }

        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)

        return recognizer.dominantLanguage?.rawValue
    }

    private func createSceneDescription(from classifications: [(identifier: String, confidence: Float)]) -> String? {
        guard let topScene = classifications.first, topScene.confidence > 0.3 else {
            return nil
        }

        // Get top 3 scenes with reasonable confidence
        let topScenes = classifications
            .prefix(3)
            .filter { $0.confidence > 0.2 }
            .map { $0.identifier }

        return topScenes.joined(separator: ", ")
    }

    private func calculateConfidence(for data: ExtractedData, basicEntities: BasicEntities) -> Double {
        var totalScore = 0.0
        var maxScore = 0.0

        // Basic entities presence
        maxScore += 0.3
        if basicEntities.hasAnyEntity {
            totalScore += 0.3
        }

        // Text content
        maxScore += 0.2
        if let text = data.fullText, !text.isEmpty {
            totalScore += 0.2
        }

        // Event detection
        maxScore += 0.2
        if data.eventDate != nil {
            totalScore += 0.2
        }

        // Contact detection
        maxScore += 0.2
        if data.contactName != nil {
            totalScore += 0.2
        }

        // Scene classification
        maxScore += 0.1
        if data.sceneDescription != nil {
            totalScore += 0.1
        }

        return totalScore / maxScore
    }
}

