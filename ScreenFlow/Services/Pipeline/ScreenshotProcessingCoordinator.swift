//
//  ScreenshotProcessingCoordinator.swift
//  ScreenFlow
//
//  Coordinator for orchestrating the screenshot processing pipeline
//

import UIKit

/// Coordinates the complete screenshot processing pipeline
///
/// Pipeline order:
/// 1. OCR (ScreenshotAnalysisService) - Image → OCR blocks + raw text
/// 2. Markdown Conversion (MarkdownConverterService) - OCR blocks → Markdown
/// 3. Entity Extraction (EntityExtractionService) - Raw text + Markdown → Entities
/// 4. Data Assembly (ExtractedDataBuilder) - Combine all results
final class ScreenshotProcessingCoordinator {

    // MARK: - Properties

    static let shared = ScreenshotProcessingCoordinator()

    private let screenshotService: ScreenshotAnalysisServiceProtocol
    private let markdownService: MarkdownConverterServiceProtocol
    private let entityService: EntityExtractionServiceProtocol
    private let dataBuilder: ExtractedDataBuilderProtocol

    // MARK: - Initialization

    init(
        screenshotService: ScreenshotAnalysisServiceProtocol = OCRService.shared,
        markdownService: MarkdownConverterServiceProtocol = MarkdownConverterService.shared,
        entityService: EntityExtractionServiceProtocol = EntityExtractionPipelineService.shared,
        dataBuilder: ExtractedDataBuilderProtocol = ExtractedDataBuilder.shared
    ) {
        self.screenshotService = screenshotService
        self.markdownService = markdownService
        self.entityService = entityService
        self.dataBuilder = dataBuilder
    }

    // MARK: - Public API

    /// Process a screenshot image through the complete pipeline
    ///
    /// - Parameter image: The screenshot image to process
    /// - Returns: Complete processed screenshot data
    /// - Throws: Processing errors from any stage
    func process(image: UIImage) async throws -> ProcessedScreenshotData {
        // Stage 1: OCR - Extract text blocks and raw text
        let ocrResult = try await screenshotService.analyze(image: image)

        // Stage 2: Markdown Conversion - Convert OCR blocks to structured Markdown
        // Uses Apple Intelligence (iOS 18+) or heuristic fallback
        let markdown = try await markdownService.convertToMarkdown(blocks: ocrResult.ocrBlocks)

        // Stage 3: Entity Extraction - Extract structured entities from text
        // Works on raw text, can optionally use markdown structure
        let entitiesResult = try await entityService.extractEntities(
            from: ocrResult.rawText,
            markdown: markdown
        )

        // Stage 4: Data Assembly - Build final output
        return dataBuilder.buildExtractedData(
            ocrResult: ocrResult,
            markdownText: markdown,
            entityResult: entitiesResult
        )
    }

    /// Get information about the current processing engines
    var engineInfo: String {
        let markdownEngine = markdownService.engine == .appleIntelligence
            ? "Apple Intelligence"
            : "Heuristic"
        return "Markdown: \(markdownEngine)"
    }
}
