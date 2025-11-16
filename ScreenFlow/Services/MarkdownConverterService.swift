//
//  MarkdownConverterService.swift
//  ScreenFlow
//
//  Offline image-to-Markdown converter service.
//  Uses Vision OCR + Apple Intelligence (if available) or heuristic fallback.
//

import UIKit
import Vision
#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - Engine Kind

/// Determines which Markdown reconstruction engine to use.
enum MarkdownEngineKind {
    case appleIntelligence  // Uses on-device SystemLanguageModel (iOS 18+)
    case heuristic          // Uses geometric layout analysis only
}

// MARK: - OCR Block

/// Represents a single text block from OCR with normalized coordinates.
///
/// Coordinates are normalized (0–1) using Vision's coordinate system:
/// - Origin: bottom-left
/// - x/y: [0, 1]
/// - x increases rightward
/// - y increases upward
struct OcrBlock: Codable {
    let text: String
    let x: Double
    let y: Double
    let width: Double
    let height: Double
}

// MARK: - Markdown Converter Service

/// Converts images to Markdown using OCR and intelligent reconstruction.
///
/// The service automatically selects between two engines:
/// - Apple Intelligence: On-device LLM reconstruction (iOS 18+ with availability check)
/// - Heuristic: Pure geometric layout analysis (always available, offline)
final class MarkdownConverterService {

    // MARK: - Properties

    static let shared = MarkdownConverterService()

    private let engine: MarkdownEngineKind

    // MARK: - Initialization

    private init() {
        // Determine which engine to use based on Apple Intelligence availability
        if #available(iOS 18.0, *) {
            #if canImport(FoundationModels)
            if SystemLanguageModel.default.isAvailable {
                self.engine = .appleIntelligence
            } else {
                self.engine = .heuristic
            }
            #else
            self.engine = .heuristic
            #endif
        } else {
            self.engine = .heuristic
        }
    }

    // MARK: - Public API

    /// Converts an image to Markdown format.
    ///
    /// - Parameter image: The image to convert
    /// - Returns: Markdown string representing the document structure and content
    /// - Throws: Vision or processing errors
    func convert(image: UIImage) async throws -> String {
        // Step 1: Run OCR to extract text blocks with coordinates
        let blocks = try await recognizeTextBlocks(in: image)

        // Step 2: Convert blocks to Markdown
        return try await convert(blocks: blocks)
    }

    /// Converts pre-computed OCR blocks to Markdown format.
    ///
    /// Use this method when you already have OCR results from Vision framework
    /// to avoid redundant OCR processing.
    ///
    /// - Parameter blocks: Pre-computed OCR blocks with coordinates
    /// - Returns: Markdown string representing the document structure and content
    /// - Throws: Processing errors
    func convert(blocks: [OcrBlock]) async throws -> String {
        // If no text found, return empty string
        if blocks.isEmpty {
            return ""
        }

        // Convert blocks to Markdown using appropriate engine
        switch engine {
        case .appleIntelligence:
            if #available(iOS 18.0, *) {
                #if canImport(FoundationModels)
                return try await convertWithAppleIntelligence(blocks: blocks)
                #else
                return try await convertWithHeuristics(blocks: blocks)
                #endif
            } else {
                return try await convertWithHeuristics(blocks: blocks)
            }

        case .heuristic:
            return try await convertWithHeuristics(blocks: blocks)
        }
    }

    /// Converts Vision text observations to Markdown format.
    ///
    /// Convenience method that converts Vision observations to OCR blocks first.
    ///
    /// - Parameter observations: Vision recognized text observations
    /// - Returns: Markdown string representing the document structure and content
    /// - Throws: Processing errors
    func convert(observations: [VNRecognizedTextObservation]) async throws -> String {
        // Convert observations to OCR blocks
        let blocks = observations.compactMap { observation -> OcrBlock? in
            guard let text = observation.topCandidates(1).first?.string,
                  !text.isEmpty else {
                return nil
            }

            let rect = observation.boundingBox
            return OcrBlock(
                text: text,
                x: Double(rect.origin.x),
                y: Double(rect.origin.y),
                width: Double(rect.size.width),
                height: Double(rect.size.height)
            )
        }

        // Convert to Markdown
        return try await convert(blocks: blocks)
    }

    // MARK: - OCR (Vision Framework)

    /// Recognizes text blocks in an image using Vision framework.
    ///
    /// - Parameter image: The image to process
    /// - Returns: Array of OCR blocks with normalized coordinates (bottom-left origin, 0-1 range)
    /// - Throws: Vision processing errors
    private func recognizeTextBlocks(in image: UIImage) async throws -> [OcrBlock] {
        // Get CGImage
        guard let cgImage = image.cgImage else {
            return []
        }

        // Create and configure text recognition request
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        // Perform OCR
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        // Extract observations
        guard let observations = request.results else {
            return []
        }

        // Convert observations to OCR blocks
        var blocks: [OcrBlock] = []
        for observation in observations {
            // Get best text candidate
            guard let text = observation.topCandidates(1).first?.string,
                  !text.isEmpty else {
                continue
            }

            // Get bounding box (normalized, bottom-left origin)
            let rect = observation.boundingBox

            // Create OCR block
            let block = OcrBlock(
                text: text,
                x: Double(rect.origin.x),
                y: Double(rect.origin.y),
                width: Double(rect.size.width),
                height: Double(rect.size.height)
            )
            blocks.append(block)
        }

        return blocks
    }

    // MARK: - Apple Intelligence Path

    /// Converts OCR blocks to Markdown using on-device Apple Intelligence.
    ///
    /// - Parameter blocks: OCR blocks with coordinates
    /// - Returns: Reconstructed Markdown string
    /// - Throws: Encoding or model errors
    @available(iOS 18.0, *)
    private func convertWithAppleIntelligence(blocks: [OcrBlock]) async throws -> String {
        #if canImport(FoundationModels)
        // Encode blocks to JSON
        let encoder = JSONEncoder()
        let data = try encoder.encode(blocks)
        let jsonString = String(data: data, encoding: .utf8) ?? "[]"

        // Construct prompt for on-device LLM
        let prompt = """
        You are an OCR post-processor.

        Input:
        - JSON array of text blocks with coordinates (x, y, width, height) in normalized page coordinates.

        Task:
        - Reconstruct the original document as Markdown.
        - Preserve ALL text exactly as it appears (do not invent new content).
        - Use:
          * #, ##, ### for headings (larger or top lines)
          * Blank line between paragraphs
          * Bulleted lists (- item) and numbered lists (1., 2., ...)
          * **bold** and *italic* only when clearly used as headings or emphasis
        - Output ONLY Markdown, no explanation or extra commentary.

        OCR_BLOCKS_JSON:
        \(jsonString)
        """

        // Use SystemLanguageModel to generate Markdown
        let model = SystemLanguageModel.default
        let session = LanguageModelSession(model: model)
        let response = try await session.respond(to: prompt)

        return response.content
        #else
        // Fallback to heuristics if framework not available at runtime
        return try await convertWithHeuristics(blocks: blocks)
        #endif
    }

    // MARK: - Heuristic Path

    /// Converts OCR blocks to Markdown using geometric layout analysis only.
    ///
    /// This method is fully offline and requires no LLM or network.
    /// It uses text positioning and size to infer document structure.
    ///
    /// - Parameter blocks: OCR blocks with coordinates
    /// - Returns: Reconstructed Markdown string
    private func convertWithHeuristics(blocks: [OcrBlock]) async throws -> String {
        // A) Sort blocks by visual order (top to bottom, then left to right)
        // Vision uses bottom-left origin, so larger y = higher on page
        let sorted = blocks.sorted { a, b in
            if abs(a.y - b.y) > 0.01 {
                return a.y > b.y  // Larger y first (visually higher)
            } else {
                return a.x < b.x  // Same row: left to right
            }
        }

        // B) Estimate typical text height
        let heights = sorted.map { $0.height }
        guard !heights.isEmpty else { return "" }

        let sortedHeights = heights.sorted()
        let medianHeight = sortedHeights[sortedHeights.count / 2]
        let gapThreshold = medianHeight * 1.5

        // C) Group blocks into lines
        struct Line {
            var text: String
            var y: Double
            var height: Double
        }

        var lines: [Line] = []
        var currentText = ""
        var currentY = sorted[0].y
        var currentHeight = sorted[0].height
        var lastBlock = sorted[0]

        for (index, block) in sorted.enumerated() {
            if index == 0 {
                currentText = block.text
                continue
            }

            let dy = abs(block.y - lastBlock.y)

            if dy < gapThreshold {
                // Same logical line - append with space
                currentText += " " + block.text
                currentHeight = max(currentHeight, block.height)
            } else {
                // New line - flush current line
                lines.append(Line(text: currentText, y: currentY, height: currentHeight))
                currentText = block.text
                currentY = block.y
                currentHeight = block.height
            }

            lastBlock = block
        }

        // Flush final line
        if !currentText.isEmpty {
            lines.append(Line(text: currentText, y: currentY, height: currentHeight))
        }

        // D) Determine top band for main headings
        let maxY = lines.map { $0.y }.max() ?? 0.0
        let topBand = maxY - 0.2  // Top 20% of page

        // E) Classify lines and generate Markdown
        var mdLines: [String] = []
        var hasEmittedMainHeading = false

        for line in lines {
            let text = line.text

            // 1) Detect lists
            let numberedListPattern = "^[0-9]+[).]\\s+"
            let bulletListPattern = "^[-•*]\\s+"

            if let _ = text.range(of: numberedListPattern, options: .regularExpression) {
                // Numbered list - append as-is
                mdLines.append(text)
                continue
            }

            if let bulletRange = text.range(of: bulletListPattern, options: .regularExpression) {
                // Bullet list - normalize to "- "
                let normalized = text.replacingCharacters(in: bulletRange, with: "- ")
                mdLines.append(normalized)
                continue
            }

            // 2) Detect headings
            let isBig = line.height > medianHeight * 1.3
            let isTop = line.y > topBand
            let isShort = text.count < 40

            if (isBig && isShort) || (isTop && isShort) {
                // This is a heading
                if !hasEmittedMainHeading {
                    mdLines.append("# \(text)")
                    hasEmittedMainHeading = true
                } else {
                    mdLines.append("## \(text)")
                }
                mdLines.append("")  // Blank line after heading
                continue
            }

            // 3) Default paragraph
            mdLines.append(text)
            mdLines.append("")  // Blank line between paragraphs
        }

        // F) Trim trailing blank lines
        while let last = mdLines.last, last.trimmingCharacters(in: .whitespaces).isEmpty {
            mdLines.removeLast()
        }

        // G) Join into final Markdown
        let result = mdLines.joined(separator: "\n")
        return result
    }
}
