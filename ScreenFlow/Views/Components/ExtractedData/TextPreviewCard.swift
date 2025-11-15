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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(.purple)
                Text("Extracted Text")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }

            // Text content
            Text(text)
                .font(.body)
                .textSelection(.enabled)
                .padding(.top, 4)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}
