//
//  TextPreviewCard.swift
//  ScreenFlow
//
//  Card displaying extracted text preview
//

import SwiftUI

/// Card showing full text extracted from screenshot (styled like LinksSection)
struct TextPreviewCard: View {
    let text: String
    let isMarkdown: Bool
    @State private var copied = false

    init(text: String, isMarkdown: Bool = false) {
        self.text = text
        self.isMarkdown = isMarkdown
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with Copy button (matching LinksSection style)
            HStack(alignment: .firstTextBaseline) {
                Text("Text")
                    .font(.system(size: 20))
                    .fontWeight(.semibold)
                    .foregroundColor(Color.primary)

                Spacer()

                Button {
                    copyText()
                } label: {
                    Text(copied ? "Copied!" : "Copy")
                        .font(.system(size: 18))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)

            // Text content card
            VStack(alignment: .leading, spacing: 0) {
                if isMarkdown {
                    renderMarkdown()
                } else {
                    Text(text)
                        .font(.system(size: 17))
                }
            }
            .foregroundColor(.primary)
            .textSelection(.enabled)
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .cornerRadius(26)
            .padding(.horizontal, 16)
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
        .padding(.top, 8)
    }
    
    @ViewBuilder
    private func renderMarkdown() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(processMarkdownLines().enumerated()), id: \.offset) { index, line in
                line
            }
        }
    }
    
    private func processMarkdownLines() -> [Text] {
        // Remove markdown code block wrappers
        var cleanText = text
        if cleanText.hasPrefix("```markdown") {
            cleanText = cleanText.replacingOccurrences(of: "```markdown\n", with: "")
            cleanText = cleanText.replacingOccurrences(of: "```markdown", with: "")
        }
        if cleanText.hasSuffix("```") {
            cleanText = cleanText.replacingOccurrences(of: "\n```", with: "")
            if cleanText.hasSuffix("```") {
                cleanText = String(cleanText.dropLast(3))
            }
        }
        cleanText = cleanText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let lines = cleanText.components(separatedBy: .newlines)
        var result: [Text] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if trimmed.isEmpty {
                result.append(Text(" ").font(.system(size: 4)))
                continue
            }
            
            // H1 header
            if trimmed.hasPrefix("# ") && !trimmed.hasPrefix("## ") {
                let content = String(trimmed.dropFirst(2))
                result.append(
                    Text(content)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                )
                continue
            }
            
            // H2 header
            if trimmed.hasPrefix("## ") && !trimmed.hasPrefix("### ") {
                let content = String(trimmed.dropFirst(3))
                result.append(
                    Text(content)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                )
                continue
            }
            
            // H3 header
            if trimmed.hasPrefix("### ") {
                let content = String(trimmed.dropFirst(4))
                result.append(
                    Text(content)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                )
                continue
            }
            
            // List items
            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                let content = String(trimmed.dropFirst(2))
                result.append(
                    Text("• \(processInlineMarkdown(content))")
                        .font(.system(size: 17))
                        .foregroundColor(.primary)
                )
                continue
            }
            
            // Numbered list
            if let range = trimmed.range(of: #"^\d+\.\s+"#, options: .regularExpression) {
                let content = String(trimmed[range.upperBound...])
                result.append(
                    Text(processInlineMarkdown(content))
                        .font(.system(size: 17))
                        .foregroundColor(.primary)
                )
                continue
            }
            
            // Regular paragraph
            result.append(
                Text(processInlineMarkdown(trimmed))
                    .font(.system(size: 17))
                    .foregroundColor(.primary)
            )
        }
        
        return result
    }
    
    private func processInlineMarkdown(_ text: String) -> AttributedString {
        var result = AttributedString(text)
        
        // Process **bold**
        let boldPattern = #"\*\*([^*]+)\*\*"#
        if let regex = try? NSRegularExpression(pattern: boldPattern) {
            let nsText = text as NSString
            let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
            
            for match in matches.reversed() {
                if match.numberOfRanges > 1 {
                    let contentRange = match.range(at: 1)
                    let content = nsText.substring(with: contentRange)
                    
                    if let range = Range(match.range, in: text) {
                        let start = result.index(result.startIndex, offsetByCharacters: match.range.location)
                        let end = result.index(start, offsetByCharacters: match.range.length)
                        
                        var replacement = AttributedString(content)
                        replacement.font = .boldSystemFont(ofSize: 17)
                        
                        result.replaceSubrange(start..<end, with: replacement)
                    }
                }
            }
        }
        
        // Process *italic*
        let italicPattern = #"(?<!\*)\*([^*]+)\*(?!\*)"#
        if let regex = try? NSRegularExpression(pattern: italicPattern) {
            let currentText = String(result.characters)
            let nsText = currentText as NSString
            let matches = regex.matches(in: currentText, range: NSRange(location: 0, length: nsText.length))
            
            for match in matches.reversed() {
                if match.numberOfRanges > 1 {
                    let contentRange = match.range(at: 1)
                    let content = nsText.substring(with: contentRange)
                    
                    if let range = Range(match.range, in: currentText) {
                        let start = result.index(result.startIndex, offsetByCharacters: match.range.location)
                        let end = result.index(start, offsetByCharacters: match.range.length)
                        
                        var replacement = AttributedString(content)
                        replacement.font = .italicSystemFont(ofSize: 17)
                        
                        result.replaceSubrange(start..<end, with: replacement)
                    }
                }
            }
        }
        
        return result
    }

    // MARK: - Actions

    private func copyText() {
        UIPasteboard.general.string = text
        copied = true

        // Reset after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copied = false
        }
    }
}
