//
//  DetectedObject.swift
//  ScreenFlow
//
//  SwiftData model for storing detected objects in screenshots
//

import Foundation
import SwiftData

/// Represents an object detected in a screenshot
@Model
final class DetectedObject {
    // MARK: - Relationships

    /// Parent extracted data
    var extractedData: ExtractedData?

    // MARK: - Object Data

    /// Object label/category (e.g., "car", "shoes", "document")
    var label: String

    /// Additional details about the object (e.g., "black", "Nike", "green Chevrolet")
    var details: String?

    /// Detection confidence score (0.0 - 1.0)
    var confidence: Float

    /// Bounding box coordinates as JSON string
    /// Format: {"x": 0.1, "y": 0.2, "width": 0.3, "height": 0.4}
    var boundingBox: String?

    // MARK: - Initialization

    init(label: String, details: String? = nil, confidence: Float = 0.0) {
        self.label = label
        self.details = details
        self.confidence = confidence
        self.boundingBox = nil
    }
}
