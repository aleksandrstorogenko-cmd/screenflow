//
//  MarkdownConverterService.swift
//  ScreenFlow
//
//  Service for converting OCR blocks to Markdown.
//  Uses Apple Intelligence (iOS 26+) or heuristic fallback.
//

import UIKit
#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - Markdown Converter Service

/// Converts OCR blocks to Markdown using intelligent reconstruction.
///
/// The service automatically selects between two engines:
/// - Apple Intelligence: On-device LLM reconstruction (iOS 26+ with availability check)
/// - Heuristic: Pure geometric layout analysis (always available, offline)
final class MarkdownConverterService: MarkdownConverterServiceProtocol {

    // MARK: - Properties

    static let shared = MarkdownConverterService()

    /// Current engine being used
    let engine: MarkdownEngineKind

    // MARK: - Initialization

    private init() {
        // Determine which engine to use based on Apple Intelligence availability
        if #available(iOS 26.0, *) {
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

    // MARK: - MarkdownConverterServiceProtocol

    /// Convert OCR blocks to Markdown format
    ///
    /// - Parameter blocks: OCR blocks with coordinates
    /// - Returns: Markdown-formatted text
    /// - Throws: Processing errors
    func convertToMarkdown(blocks: [OcrBlock]) async throws -> String {
        // If no text found, return empty string
        if blocks.isEmpty {
            return ""
        }

        // Convert blocks to Markdown using appropriate engine
        switch engine {
        case .appleIntelligence:
            if #available(iOS 26.0, *) {
                #if canImport(FoundationModels)
                // Try Apple Intelligence path, but fall back to heuristics on any error
                do {
                    return try await convertWithAppleIntelligence(blocks: blocks)
                } catch {
                    print("Apple Intelligence conversion failed, falling back to heuristics: \(error)")
                    // Ensure heuristic fallback never fails
                    do {
                        return try await convertWithHeuristics(blocks: blocks)
                    } catch {
                        print("Heuristic conversion also failed, returning plain text: \(error)")
                        // Last resort: return plain text joined with newlines
                        return blocks.map { $0.text }.joined(separator: "\n")
                    }
                }
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

    // MARK: - Apple Intelligence Path

    /// Converts OCR blocks to Markdown using on-device Apple Intelligence.
    ///
    /// - Parameter blocks: OCR blocks with coordinates
    /// - Returns: Reconstructed Markdown string
    /// - Throws: Encoding or model errors
    @available(iOS 26.0, *)
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
        // Safety check - return empty string if no blocks
        guard !blocks.isEmpty else { return "" }

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

        // Safety check - ensure we have at least one block
        guard !sorted.isEmpty else { return "" }

        var currentText = sorted[0].text
        var currentY = sorted[0].y
        var currentHeight = sorted[0].height
        var lastBlock = sorted[0]

        for (index, block) in sorted.enumerated() {
            if index == 0 {
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
