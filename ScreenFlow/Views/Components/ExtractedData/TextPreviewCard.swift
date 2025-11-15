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
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with Copy button (matching LinksSection style)
            HStack(alignment: .firstTextBaseline) {
                Text("Extracted Text")
                    .font(.system(size: 20))
                    .fontWeight(.semibold)
                    .foregroundColor(Color(.systemGray))

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
                Text(text)
                    .font(.system(size: 17))
                    .foregroundColor(.primary)
                    .textSelection(.enabled)
                    .padding(20)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .cornerRadius(24)
            .padding(.horizontal, 16)
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
        .padding(.top, 8)
    }

    private func copyText() {
        UIPasteboard.general.string = text
        copied = true

        // Reset after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copied = false
        }
    }
}
