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
                    Text(attributedText)
                        .textSelection(.enabled)
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text(text)
                        .font(.system(size: 17))
                        .foregroundColor(.primary)
                        .textSelection(.enabled)
                        .padding(20)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .cornerRadius(24)
            .padding(.horizontal, 16)
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
        .padding(.top, 8)
    }

    // MARK: - Computed Properties

    /// Convert markdown text to AttributedString with proper formatting
    private var attributedText: AttributedString {
        do {
            // Parse markdown with full syntax support
            var options = AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .full,
                failurePolicy: .returnPartiallyParsedIfPossible
            )
            options.allowsExtendedAttributes = true

            var attributed = try AttributedString(markdown: text, options: options)

            // Apply base font to ensure consistent sizing
            attributed.font = .system(size: 17)

            // Apply custom styling for headings
            for run in attributed.runs {
                if let presentationIntent = run.presentationIntent {
                    if presentationIntent.components.contains(where: { component in
                        if case .header(level: 1) = component.kind {
                            return true
                        }
                        return false
                    }) {
                        // H1 - larger, bold
                        attributed[run.range].font = .system(size: 24, weight: .bold)
                    } else if presentationIntent.components.contains(where: { component in
                        if case .header(level: 2) = component.kind {
                            return true
                        }
                        return false
                    }) {
                        // H2 - medium, semibold
                        attributed[run.range].font = .system(size: 20, weight: .semibold)
                    } else if presentationIntent.components.contains(where: { component in
                        if case .header = component.kind {
                            return true
                        }
                        return false
                    }) {
                        // Other headings - slightly larger, medium weight
                        attributed[run.range].font = .system(size: 18, weight: .medium)
                    }
                }
            }

            return attributed
        } catch {
            // Fallback to plain text if markdown parsing fails
            var fallback = AttributedString(text)
            fallback.font = .system(size: 17)
            return fallback
        }
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
