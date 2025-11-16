//
//  PipelineProtocols.swift
//  ScreenFlow
//
//  Protocols for the screenshot processing pipeline services
//

import UIKit

// MARK: - Screenshot Analysis Service Protocol

/// Service for performing OCR on screenshots
protocol ScreenshotAnalysisServiceProtocol: AnyObject {
    /// Analyze an image and extract text with coordinates
    ///
    /// - Parameter image: The image to analyze
    /// - Returns: OCR result with blocks and raw text
    /// - Throws: Vision or processing errors
    func analyze(image: UIImage) async throws -> ScreenshotAnalysisResult
}

// MARK: - Markdown Converter Service Protocol

/// Engine type for Markdown conversion
enum MarkdownEngineKind: Sendable {
    case appleIntelligence  // Uses on-device SystemLanguageModel (iOS 18+)
    case heuristic          // Uses geometric layout analysis only
}

/// Service for converting OCR blocks to Markdown
protocol MarkdownConverterServiceProtocol: AnyObject {
    /// Current engine being used
    var engine: MarkdownEngineKind { get }

    /// Convert OCR blocks to Markdown format
    ///
    /// - Parameter blocks: OCR blocks with coordinates
    /// - Returns: Markdown-formatted text
    /// - Throws: Processing errors
    func convertToMarkdown(blocks: [OcrBlock]) async throws -> String
}

// MARK: - Entity Extraction Service Protocol

/// Service for extracting structured entities from text
protocol EntityExtractionServiceProtocol: AnyObject {
    /// Extract entities from raw text
    ///
    /// - Parameters:
    ///   - rawText: Plain OCR text
    ///   - markdown: Optional Markdown-formatted text (for structure hints)
    /// - Returns: Extracted entities and normalized text
    /// - Throws: Processing errors
    func extractEntities(from rawText: String, markdown: String?) async throws -> EntityExtractionResult
}

// MARK: - Extracted Data Builder Protocol

/// Service for assembling final pipeline output
protocol ExtractedDataBuilderProtocol: AnyObject {
    /// Build final extracted data from pipeline stages
    ///
    /// - Parameters:
    ///   - ocrResult: OCR analysis result
    ///   - markdownText: Markdown-formatted text
    ///   - entityResult: Entity extraction result
    /// - Returns: Complete processed screenshot data
    func buildExtractedData(
        ocrResult: ScreenshotAnalysisResult,
        markdownText: String,
        entityResult: EntityExtractionResult
    ) -> ProcessedScreenshotData
}
