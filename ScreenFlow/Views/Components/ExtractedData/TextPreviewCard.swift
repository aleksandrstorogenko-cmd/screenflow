//
//  TextPreviewCard.swift
//  ScreenFlow
//
//  Card displaying extracted text preview
//

import SwiftUI

/// Card showing full text extracted from screenshot
struct TextPreviewCard: View {
    let text: String
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundColor(.purple)
                    Text("Extracted Text")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Text content
            if isExpanded {
                Text(text)
                    .font(.body)
                    .textSelection(.enabled)
                    .padding(.top, 4)
            } else {
                Text(text)
                    .font(.body)
                    .lineLimit(3)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}
