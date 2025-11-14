//
//  ObjectDetectionResult.swift
//  ScreenFlow
//
//  Structure for object detection results
//

import Foundation
import CoreGraphics

/// Result from object detection
struct ObjectDetectionResult {
    let label: String
    let confidence: Float
    let boundingBox: CGRect
    let attributes: [String: String]?

    init(label: String, confidence: Float, boundingBox: CGRect, attributes: [String: String]? = nil) {
        self.label = label
        self.confidence = confidence
        self.boundingBox = boundingBox
        self.attributes = attributes
    }
}
