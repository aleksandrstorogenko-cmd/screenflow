//
//  ExtractedDataBuilder.swift
//  ScreenFlow
//
//  Service for assembling final pipeline output
//

import Foundation

/// Service for building ProcessedScreenshotData from pipeline results
final class ExtractedDataBuilder: ExtractedDataBuilderProtocol {

    // MARK: - Properties

    static let shared = ExtractedDataBuilder()

    private init() {}

    // MARK: - ExtractedDataBuilderProtocol

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
    ) -> ProcessedScreenshotData {
        return ProcessedScreenshotData(
            rawText: entityResult.normalizedText,
            formattedText: markdownText,
            entities: entityResult.entities,
            ocrBlocks: ocrResult.ocrBlocks,
            detectedLanguage: entityResult.detectedLanguage
        )
    }
}
