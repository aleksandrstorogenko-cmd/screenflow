//
//  TextFormatterService.swift
//  ScreenFlow
//
//  DEPRECATED: Use ScreenshotProcessingCoordinator and MarkdownConverterService instead.
//  This service is kept for backward compatibility only.
//

import Foundation
import Vision
import NaturalLanguage

/// Service for converting plain extracted text into markdown-formatted text
///
/// **DEPRECATED**: This service is no longer used in the new pipeline architecture.
/// Use `ScreenshotProcessingCoordinator` for complete screenshot processing,
/// or `MarkdownConverterService.convertToMarkdown(blocks:)` directly.
///
/// This service is kept for backward compatibility but will be removed in a future version.
@available(*, deprecated, message: "Use ScreenshotProcessingCoordinator or MarkdownConverterService.convertToMarkdown(blocks:) instead")
final class TextFormatterService {
    static let shared = TextFormatterService()

    private let markdownConverter = MarkdownConverterService.shared

    private init() {}

    // MARK: - Public API

    /// Format text into markdown using Vision observations for layout analysis
    /// - Parameters:
    ///   - text: Plain text extracted from screenshot
    ///   - observations: Vision text observations with bounding boxes
    /// - Returns: Markdown-formatted text
    @available(*, deprecated, message: "Use MarkdownConverterService.convertToMarkdown(blocks:) instead")
    func formatAsMarkdown(text: String, observations: [VNRecognizedTextObservation]) async -> String {
        guard !text.isEmpty else { return text }

        // If we don't have observations, fall back to simple heuristic-based formatting
        guard !observations.isEmpty else {
            return formatWithHeuristics(text: text)
        }

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

        // Use the new MarkdownConverterService for intelligent conversion
        // This supports both Apple Intelligence and advanced heuristics
        do {
            return try await markdownConverter.convertToMarkdown(blocks: blocks)
        } catch {
            // Fallback to basic heuristics on error
            return formatWithHeuristics(text: text)
        }
    }

    // MARK: - Layout Analysis

    /// Represents a line of text with its layout properties
    private struct TextLine {
        let text: String
        let boundingBox: CGRect
        let confidence: Float

        var fontSize: CGFloat {
            boundingBox.height
        }

        var xPosition: CGFloat {
            boundingBox.minX
        }

        var yPosition: CGFloat {
            boundingBox.minY
        }
    }

    /// Extract lines with layout information from Vision observations
    private func extractLinesWithLayout(from observations: [VNRecognizedTextObservation]) -> [TextLine] {
        return observations.compactMap { observation in
            guard let candidate = observation.topCandidates(1).first else { return nil }

            return TextLine(
                text: candidate.string,
                boundingBox: observation.boundingBox,
                confidence: candidate.confidence
            )
        }.sorted { $0.yPosition > $1.yPosition } // Sort top to bottom (Vision coords are flipped)
    }

    /// Convert analyzed lines to markdown
    private func convertToMarkdown(lines: [TextLine], originalText: String) -> String {
        guard !lines.isEmpty else { return originalText }

        var result: [String] = []
        var previousLine: TextLine?

        // Calculate average font size for comparison
        let avgFontSize = lines.map { $0.fontSize }.reduce(0, +) / CGFloat(lines.count)
        // Much higher thresholds to avoid false positives
        let largeThreshold = avgFontSize * 1.8
        let mediumThreshold = avgFontSize * 1.5

        // Calculate average indentation
        let avgIndent = lines.map { $0.xPosition }.reduce(0, +) / CGFloat(lines.count)

        for line in lines {
            let trimmedText = line.text.trimmingCharacters(in: .whitespaces)
            guard !trimmedText.isEmpty else {
                // Add blank line for spacing
                if let prev = result.last, !prev.isEmpty {
                    result.append("")
                }
                continue
            }

            var formattedLine = trimmedText

            // Very conservative heading detection - only for clearly distinct titles
            // Must be significantly larger AND relatively short
            if line.fontSize > largeThreshold && trimmedText.count < 60 {
                // Large text = main heading (only if it's a short, distinct title)
                formattedLine = "**\(trimmedText)**"  // Use bold instead of H1
            } else if line.fontSize > mediumThreshold && trimmedText.count < 50 {
                // Medium-large text = subheading (only if short)
                formattedLine = "**\(trimmedText)**"  // Use bold instead of H2
            }
            // Detect list items
            else if trimmedText.hasPrefix("-") || trimmedText.hasPrefix("•") || trimmedText.hasPrefix("*") {
                // Already a list item, ensure proper markdown format
                let content = trimmedText.dropFirst().trimmingCharacters(in: .whitespaces)
                formattedLine = "- \(content)"
            }
            // Detect numbered lists
            else if let match = trimmedText.range(of: #"^(\d+)[.)]\s"#, options: .regularExpression) {
                let number = trimmedText[..<match.upperBound].trimmingCharacters(in: CharacterSet.decimalDigits.inverted)
                let content = trimmedText[match.upperBound...].trimmingCharacters(in: .whitespaces)
                formattedLine = "\(number). \(content)"
            }
            // Detect indented text (quotes or nested content)
            else if line.xPosition > avgIndent * 1.2 {
                formattedLine = "> \(trimmedText)"
            }
            // Detect potential labels by pattern (ends with colon, short length)
            else if trimmedText.hasSuffix(":") && trimmedText.count < 50 {
                formattedLine = "**\(trimmedText)**"
            }
            // Detect URLs and emails - make them proper links
            else if isURL(trimmedText) {
                formattedLine = "<\(trimmedText)>"
            }
            // Detect potential code or technical content
            else if looksLikeCode(trimmedText) {
                formattedLine = "`\(trimmedText)`"
            }

            // Add spacing between sections - more generous to preserve paragraph breaks
            if let prev = previousLine {
                let verticalGap = abs(prev.yPosition - line.yPosition)
                let avgHeight = (prev.fontSize + line.fontSize) / 2

                // Add blank line for larger gaps (paragraph breaks)
                if verticalGap > avgHeight * 1.2 {
                    result.append("")
                }
            }

            result.append(formattedLine)
            previousLine = line
        }

        // Join with explicit newlines to ensure proper line breaks
        return result.joined(separator: "\n")
    }

    // MARK: - Heuristic Formatting (Fallback)

    /// Format text using heuristics when Vision observations are not available
    private func formatWithHeuristics(text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        var result: [String] = []
        var previousLineWasEmpty = false

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Preserve empty lines for paragraph spacing
            if trimmed.isEmpty {
                if !previousLineWasEmpty && !result.isEmpty {
                    result.append("")
                    previousLineWasEmpty = true
                }
                continue
            }

            previousLineWasEmpty = false
            var formattedLine = trimmed

            // Lines ending with colon are likely labels
            if trimmed.hasSuffix(":") && trimmed.count < 50 {
                formattedLine = "**\(trimmed)**"
            }
            // List items
            else if trimmed.hasPrefix("-") || trimmed.hasPrefix("•") || trimmed.hasPrefix("*") {
                let content = trimmed.dropFirst().trimmingCharacters(in: .whitespaces)
                formattedLine = "- \(content)"
            }
            // Numbered lists
            else if let match = trimmed.range(of: #"^(\d+)[.)]\s"#, options: .regularExpression) {
                let number = trimmed[..<match.upperBound].trimmingCharacters(in: CharacterSet.decimalDigits.inverted)
                let content = trimmed[match.upperBound...].trimmingCharacters(in: .whitespaces)
                formattedLine = "\(number). \(content)"
            }
            // URLs and emails
            else if isURL(trimmed) {
                formattedLine = "<\(trimmed)>"
            }
            // Code-like content
            else if looksLikeCode(trimmed) {
                formattedLine = "`\(trimmed)`"
            }
            // Phone numbers
            else if isPhoneNumber(trimmed) {
                formattedLine = "**\(trimmed)**"
            }

            result.append(formattedLine)
        }

        return result.joined(separator: "\n")
    }

    // MARK: - Detection Helpers

    private func isURL(_ text: String) -> Bool {
        // Check if text is a URL
        if text.hasPrefix("http://") || text.hasPrefix("https://") || text.hasPrefix("www.") {
            return true
        }

        // Check for URL pattern
        let urlPattern = #"^[a-zA-Z0-9-]+\.[a-zA-Z]{2,}(/.*)?$"#
        return text.range(of: urlPattern, options: .regularExpression) != nil
    }

    private func looksLikeCode(_ text: String) -> Bool {
        // Detect code patterns: contains brackets, braces, or typical code symbols
        let codeIndicators = ["{", "}", "[", "]", "=>", "->", "==", "!=", "<=", ">=", "&&", "||"]
        let hasCodeSymbols = codeIndicators.contains { text.contains($0) }

        // File paths
        let isFilePath = text.hasPrefix("/") || text.hasPrefix("~/") || text.contains("\\")

        // Contains many underscores or camelCase
        let hasUnderscores = text.filter { $0 == "_" }.count >= 2
        let hasCamelCase = text.range(of: #"[a-z][A-Z]"#, options: .regularExpression) != nil

        return hasCodeSymbols || isFilePath || (hasUnderscores && text.count < 40) || (hasCamelCase && text.count < 40)
    }

    private func isPhoneNumber(_ text: String) -> Bool {
        // Detect phone number patterns
        let phonePattern = #"^[\+]?[(]?[0-9]{1,4}[)]?[-\s\.]?[(]?[0-9]{1,4}[)]?[-\s\.]?[0-9]{1,9}$"#
        return text.range(of: phonePattern, options: .regularExpression) != nil
    }
}
