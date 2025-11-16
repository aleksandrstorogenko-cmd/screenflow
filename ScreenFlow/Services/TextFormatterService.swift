//
//  TextFormatterService.swift
//  ScreenFlow
//
//  Service for formatting extracted text into markdown using layout analysis
//

import Foundation
import Vision
import NaturalLanguage

/// Service for converting plain extracted text into markdown-formatted text
final class TextFormatterService {
    static let shared = TextFormatterService()

    private init() {}

    // MARK: - Public API

    /// Format text into markdown using Vision observations for layout analysis
    /// - Parameters:
    ///   - text: Plain text extracted from screenshot
    ///   - observations: Vision text observations with bounding boxes
    /// - Returns: Markdown-formatted text
    func formatAsMarkdown(text: String, observations: [VNRecognizedTextObservation]) -> String {
        guard !text.isEmpty else { return text }

        // If we don't have observations, fall back to heuristic-based formatting
        guard !observations.isEmpty else {
            return formatWithHeuristics(text: text)
        }

        // Analyze layout from observations
        let lines = extractLinesWithLayout(from: observations)

        // Convert to markdown
        return convertToMarkdown(lines: lines, originalText: text)
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
        let largeThreshold = avgFontSize * 1.3
        let mediumThreshold = avgFontSize * 1.15

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

            // Detect headings based on font size
            if line.fontSize > largeThreshold {
                // Large text = main heading
                formattedLine = "# \(trimmedText)"
            } else if line.fontSize > mediumThreshold {
                // Medium-large text = subheading
                formattedLine = "## \(trimmedText)"
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
            // Detect potential headings by pattern (ends with colon, short length)
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

            // Add spacing between sections
            if let prev = previousLine {
                let verticalGap = abs(prev.yPosition - line.yPosition)
                let avgHeight = (prev.fontSize + line.fontSize) / 2

                // Large vertical gap = new section
                if verticalGap > avgHeight * 1.5 {
                    result.append("")
                }
            }

            result.append(formattedLine)
            previousLine = line
        }

        return result.joined(separator: "\n")
    }

    // MARK: - Heuristic Formatting (Fallback)

    /// Format text using heuristics when Vision observations are not available
    private func formatWithHeuristics(text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        var result: [String] = []
        var inCodeBlock = false

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Skip empty lines but preserve spacing
            if trimmed.isEmpty {
                if !result.isEmpty && !result.last!.isEmpty {
                    result.append("")
                }
                continue
            }

            var formattedLine = trimmed

            // First line with substantial text might be a title
            if index == 0 && trimmed.count > 5 && trimmed.count < 60 {
                formattedLine = "# \(trimmed)"
            }
            // Lines ending with colon are likely labels/headings
            else if trimmed.hasSuffix(":") && trimmed.count < 50 {
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
