//
//  PipelineModels.swift
//  ScreenFlow
//
//  Data models for the screenshot processing pipeline
//

import Foundation

// MARK: - OCR Block

/// Represents a single text block from OCR with normalized coordinates.
///
/// Coordinates are normalized (0–1) using Vision's coordinate system:
/// - Origin: bottom-left
/// - x/y: [0, 1]
/// - x increases rightward
/// - y increases upward
struct OcrBlock: Codable, Sendable {
    let text: String
    let x: Double
    let y: Double
    let width: Double
    let height: Double
}

// MARK: - Screenshot Analysis Result

/// Result returned by OCR stage
struct ScreenshotAnalysisResult: Sendable {
    /// OCR blocks with coordinates
    let ocrBlocks: [OcrBlock]

    /// All OCR text joined in reading order
    let rawText: String
}

// MARK: - Entity Models

/// Types of entities that can be extracted from text
enum ExtractedEntityKind: String, Codable, Sendable {
    case person
    case organization
    case event
    case date
    case phone
    case email
    case location
    case url
    case address
    case custom
}

/// Represents an extracted entity from text
struct ExtractedEntity: Codable, Sendable {
    /// Type of entity
    let kind: ExtractedEntityKind

    /// Entity value/text
    let value: String

    /// Optional range in source text
    let range: NSRange?

    /// Optional metadata (e.g., confidence, sub-type)
    let metadata: [String: String]?

    init(kind: ExtractedEntityKind, value: String, range: NSRange? = nil, metadata: [String: String]? = nil) {
        self.kind = kind
        self.value = value
        self.range = range
        self.metadata = metadata
    }
}

// MARK: - Entity Extraction Result

/// Result returned by entity extraction stage
struct EntityExtractionResult: Sendable {
    /// Extracted entities
    let entities: [ExtractedEntity]

    /// Normalized text (usually same as input, but can be cleaned up)
    let normalizedText: String

    /// Detected language (ISO code)
    let detectedLanguage: String?
}

// MARK: - Extracted Data (Pipeline Output)

/// Final data structure for the processing pipeline
///
/// This is the output of the pipeline coordinator and is used to populate
/// the SwiftData ExtractedData model for persistence.
struct ProcessedScreenshotData: Sendable {
    /// Plain OCR text
    let rawText: String

    /// Markdown-formatted text
    let formattedText: String

    /// Extracted entities
    let entities: [ExtractedEntity]

    /// OCR blocks (for debugging/future features)
    let ocrBlocks: [OcrBlock]

    /// Detected language
    let detectedLanguage: String?
}
