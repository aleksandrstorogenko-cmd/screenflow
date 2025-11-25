//
//  MarkdownConverterService.swift
//  ScreenFlow
//
//  Service for converting OCR blocks to Markdown.
//  Uses Apple Intelligence (iOS 26+) or heuristic fallback.
//

import UIKit
import SwiftUI
#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - Markdown Converter Service

/// Converts OCR blocks to Markdown using intelligent reconstruction.
///
/// The service automatically selects between engines:
/// - Apple Intelligence: On-device LLM reconstruction (iOS 26+ with availability check)
/// - Heuristic: Pure geometric layout analysis with smart filtering (always available, offline)
final class MarkdownConverterService: MarkdownConverterServiceProtocol {

    // MARK: - Properties

    static let shared = MarkdownConverterService()

    /// Current engine being used
    let engine: MarkdownEngineKind
    
    /// Text extraction service for rule-based filtering
    private let textExtraction = TextExtractionService.shared

    /// Maximum number of OCR blocks per chunk for Apple Intelligence
    private let maxBlocksPerChunk = 40

    /// Maximum total text length per chunk for Apple Intelligence processing
    private let maxTextLengthPerChunk = 1800

    // MARK: - Initialization

    private init() {
        // Determine which engine to use based on Apple Intelligence availability
        if #available(iOS 26.0, *) {
            #if canImport(FoundationModels)
            // Check if Apple Intelligence is available on this device
            let isAIAvailable = SystemLanguageModel.default.isAvailable
            print("MarkdownConverterService: Apple Intelligence available: \(isAIAvailable)")

            if isAIAvailable {
                self.engine = .appleIntelligence
                print("MarkdownConverterService: Using Apple Intelligence engine")
            } else {
                self.engine = .heuristic
                print("MarkdownConverterService: Apple Intelligence not available, using heuristic engine")
            }
            #else
            self.engine = .heuristic
            print("MarkdownConverterService: FoundationModels not available, using heuristic engine")
            #endif
        } else {
            self.engine = .heuristic
            print("MarkdownConverterService: iOS < 26, using heuristic engine")
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
                // Try Apple Intelligence path with chunking support, fall back to heuristics on error
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
    /// Automatically chunks large inputs for optimal performance.
    ///
    /// - Parameter blocks: OCR blocks with coordinates
    /// - Returns: Reconstructed Markdown string
    /// - Throws: Encoding or model errors
    @available(iOS 26.0, *)
    private func convertWithAppleIntelligence(blocks: [OcrBlock]) async throws -> String {
        #if canImport(FoundationModels)
        // Check if we need to chunk the input
        let totalTextLength = blocks.reduce(0) { $0 + $1.text.count }
        let needsChunking = blocks.count > maxBlocksPerChunk || totalTextLength > maxTextLengthPerChunk
        
        if needsChunking {
            print("MarkdownConverterService: Large input (\(blocks.count) blocks, \(totalTextLength) chars), processing in chunks...")
            return try await convertWithChunking(blocks: blocks)
        }
        
        // Process as single chunk
        return try await convertChunk(blocks: blocks)
        #else
        // Fallback to heuristics if framework not available at runtime
        return try await convertWithHeuristics(blocks: blocks)
        #endif
    }

    /// Process blocks in chunks and combine results
    @available(iOS 26.0, *)
    private func convertWithChunking(blocks: [OcrBlock]) async throws -> String {
        #if canImport(FoundationModels)
        // Sort blocks by visual order (top to bottom, left to right)
        let sorted = blocks.sorted { a, b in
            if abs(a.y - b.y) > 0.01 {
                return a.y > b.y  // Larger y first (visually higher)
            } else if abs(a.x - b.x) > 0.01 {
                return a.x < b.x  // Same row: left to right
            } else {
                return a.text < b.text  // Tie-breaker for deterministic ordering
            }
        }
        
        // Split into chunks based on both block count and text length
        var chunks: [[OcrBlock]] = []
        var currentChunk: [OcrBlock] = []
        var currentTextLength = 0
        
        for block in sorted {
            let blockTextLength = block.text.count
            
            // Check if adding this block would exceed limits
            let wouldExceedBlockLimit = currentChunk.count >= maxBlocksPerChunk
            let wouldExceedTextLimit = currentTextLength + blockTextLength > maxTextLengthPerChunk
            
            if !currentChunk.isEmpty && (wouldExceedBlockLimit || wouldExceedTextLimit) {
                // Start new chunk
                chunks.append(currentChunk)
                currentChunk = [block]
                currentTextLength = blockTextLength
            } else {
                // Add to current chunk
                currentChunk.append(block)
                currentTextLength += blockTextLength
            }
        }
        
        // Add final chunk
        if !currentChunk.isEmpty {
            chunks.append(currentChunk)
        }
        
        print("MarkdownConverterService: Split into \(chunks.count) chunks")
        
        // Process chunks in parallel for speed
        let results = try await withThrowingTaskGroup(of: (Int, String).self) { group in
            for (index, chunk) in chunks.enumerated() {
                group.addTask {
                    let markdown = try await self.convertChunk(blocks: chunk)
                    return (index, markdown)
                }
            }
            
            var indexed: [(Int, String)] = []
            for try await result in group {
                indexed.append(result)
            }
            return indexed.sorted { $0.0 < $1.0 }.map { $0.1 }
        }
        
        // Combine chunks with proper spacing
        return results.joined(separator: "\n\n")
        #else
        return try await convertWithHeuristics(blocks: blocks)
        #endif
    }

    /// Convert a single chunk of blocks to Markdown
    @available(iOS 26.0, *)
    private func convertChunk(blocks: [OcrBlock]) async throws -> String {
        #if canImport(FoundationModels)
        // Use only blocks with non-empty text (detailed filtering happens in pipeline)
        let filteredBlocks = blocks.filter { block in
            let text = block.text.trimmingCharacters(in: .whitespacesAndNewlines)
            return !text.isEmpty
        }
        
        if filteredBlocks.isEmpty {
            return ""
        }
        
        // Simplify blocks but include x-position for layout context
        let simplifiedBlocks = filteredBlocks.map { block in
            [
                "text": block.text,
                "y": String(format: "%.3f", block.y),
                "height": String(format: "%.3f", block.height)
            ]
        }

        // Encode to compact JSON
        let data = try JSONSerialization.data(withJSONObject: simplifiedBlocks, options: [])
        let jsonString = String(data: data, encoding: .utf8) ?? "[]"

        // Simple formatting prompt - blocks are already cleaned
        let prompt = """
        Format OCR blocks as Markdown. Each block has: text, y-position (0-1, top→bottom), height.
        
        Rules:
        - Preserve ALL text exactly as provided (already cleaned)
        - Do NOT translate - keep original language
        - Use # for first large text block (height > others)
        - Use ## for other large text blocks
        - Add blank line between paragraphs
        - Keep lists if text starts with "-", "•", or numbers
        - Output ONLY Markdown text, NO code blocks, NO explanations
        
        Blocks:
        \(jsonString)
        """

        // Use LanguageModelSession
        let textLength = filteredBlocks.reduce(0) { $0 + $1.text.count }
        print("MarkdownConverterService: Processing chunk with \(filteredBlocks.count) blocks (\(textLength) chars) after filtering...")
        
        let session = LanguageModelSession()
        let response = try await session.respond(to: prompt)

        print("MarkdownConverterService: Received response (\(response.content.count) chars)")
        
        // Clean up response - remove code block wrappers if AI added them
        var cleanedContent = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove markdown code block wrappers
        if cleanedContent.hasPrefix("```markdown") {
            cleanedContent = cleanedContent.replacingOccurrences(of: "```markdown\n", with: "", options: [.anchored])
            cleanedContent = cleanedContent.replacingOccurrences(of: "```markdown", with: "", options: [.anchored])
        } else if cleanedContent.hasPrefix("```") {
            if let firstNewline = cleanedContent.firstIndex(of: "\n") {
                cleanedContent = String(cleanedContent[cleanedContent.index(after: firstNewline)...])
            }
        }
        
        if cleanedContent.hasSuffix("```") {
            if let lastTripleBacktick = cleanedContent.range(of: "```", options: .backwards) {
                cleanedContent = String(cleanedContent[..<lastTripleBacktick.lowerBound])
            }
        }
        
        cleanedContent = cleanedContent.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleanedContent
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
    /// Detects if content is from social media or messaging apps
    /// - Parameter blocks: OCR blocks to analyze
    /// - Returns: True if content appears to be from social media/messaging
    private func isSocialOrMessagingContent(_ blocks: [OcrBlock]) -> Bool {
        let allText = blocks.map { $0.text.lowercased() }.joined(separator: " ")
        
        let socialIndicators = [
            "like", "reply", "comment", "share", "retweet", "repost",
            "ago", "follow", "message", "chat", "send", "delivered",
            "read", "typing", "online", "dm", "pm"
        ]
        
        var indicatorCount = 0
        for indicator in socialIndicators {
            if allText.contains(indicator) {
                indicatorCount += 1
            }
        }
        
        return indicatorCount >= 3
    }
    
    private func convertWithHeuristics(blocks: [OcrBlock]) async throws -> String {
        // Safety check - return empty string if no blocks
        guard !blocks.isEmpty else { return "" }
        
        // Check if this is social media/messaging content
        let isSocialContent = isSocialOrMessagingContent(blocks)

        // A) Sort blocks by visual order (top to bottom, then left to right)
        // Vision uses bottom-left origin, so larger y = higher on page
        let sorted = blocks.sorted { a, b in
            if abs(a.y - b.y) > 0.01 {
                return a.y > b.y  // Larger y first (visually higher)
            } else if abs(a.x - b.x) > 0.01 {
                return a.x < b.x  // Same row: left to right
            } else {
                return a.text < b.text  // Tie-breaker for deterministic ordering
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

        if isSocialContent {
            // Special formatting for social media/messaging content
            // Each line is a separate message with empty lines between them
            for line in lines {
                let text = line.text
                
                // Skip obvious UI noise (already filtered by textExtraction)
                if text.count < 3 || TextFilteringRules.isSocialInteraction(text) {
                    continue
                }
                
                // Each message is a separate paragraph
                mdLines.append(text)
                mdLines.append("")  // Empty line between messages
            }
        } else {
            // Standard formatting for non-social content
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
