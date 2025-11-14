//
//  ExtractedData.swift
//  ScreenFlow
//
//  SwiftData model for storing extracted entities from screenshots
//

import Foundation
import SwiftData

/// Stores structured data extracted from a screenshot
@Model
final class ExtractedData {
    // MARK: - Relationships

    /// Parent screenshot
    var screenshot: Screenshot?

    // MARK: - Text Content

    /// Complete recognized text from the screenshot
    var fullText: String?

    /// Detected language of the text (ISO language code)
    var textLanguage: String?

    // MARK: - Basic Entities

    /// Extracted URLs
    var urls: [String] = []

    /// Extracted email addresses
    var emails: [String] = []

    /// Extracted phone numbers
    var phoneNumbers: [String] = []

    /// Extracted physical addresses
    var addresses: [String] = []

    // MARK: - Event Data

    /// Event name/title
    var eventName: String?

    /// Event start date and time
    var eventDate: Date?

    /// Event end date and time
    var eventEndDate: Date?

    /// Event location/venue
    var eventLocation: String?

    /// Event description
    var eventDescription: String?

    // MARK: - Contact/Business Card Data

    /// Contact person name
    var contactName: String?

    /// Contact company name
    var contactCompany: String?

    /// Contact job title
    var contactJobTitle: String?

    /// Contact phone number (primary)
    var contactPhone: String?

    /// Contact email address (primary)
    var contactEmail: String?

    /// Contact address
    var contactAddress: String?

    // MARK: - Object Recognition

    /// Detected objects in the screenshot
    @Relationship(deleteRule: .cascade, inverse: \DetectedObject.extractedData)
    var detectedObjects: [DetectedObject] = []

    /// Scene description from classification
    var sceneDescription: String?

    // MARK: - Metadata

    /// Date when extraction was performed
    var extractionDate: Date

    /// Overall confidence score (0.0 - 1.0)
    var confidence: Double

    // MARK: - Initialization

    init() {
        self.extractionDate = Date()
        self.confidence = 0.0
    }
}
