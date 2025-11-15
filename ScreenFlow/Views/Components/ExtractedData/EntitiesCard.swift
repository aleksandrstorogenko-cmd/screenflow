//
//  EntitiesCard.swift
//  ScreenFlow
//
//  Card displaying extracted entities (URLs, emails, phones, addresses)
//

import SwiftUI

/// Card showing general extracted entities
struct EntitiesCard: View {
    let data: ExtractedData

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "list.bullet.rectangle")
                    .foregroundColor(.green)
                Text("Extracted Info")
                    .font(.headline)
                Spacer()
            }
            .frame(maxWidth: .infinity)

            // URLs (show all, no limit, with clickable links and copy)
            if !data.urls.isEmpty {
                URLList(urls: data.urls)
            }

            // Emails
            if !data.emails.isEmpty {
                EntityList(icon: "envelope", label: "Emails", items: data.emails, limit: 5)
            }

            // Phone numbers
            if !data.phoneNumbers.isEmpty {
                EntityList(icon: "phone", label: "Phones", items: data.phoneNumbers, limit: 5)
            }

            // Addresses
            if !data.addresses.isEmpty {
                EntityList(icon: "mappin.and.ellipse", label: "Addresses", items: data.addresses, limit: 5)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    private func truncate(_ text: String, length: Int) -> String {
        if text.count > length {
            return String(text.prefix(length)) + "..."
        }
        return text
    }
}

/// List of entities with an icon
struct EntityList: View {
    let icon: String
    let label: String
    let items: [String]
    let limit: Int?

    init(icon: String, label: String, items: [String], limit: Int? = 5) {
        self.icon = icon
        self.label = label
        self.items = items
        self.limit = limit
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 20)

                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            let displayLimit = limit ?? items.count
            ForEach(Array(items.prefix(displayLimit).enumerated()), id: \.offset) { _, item in
                Text(item)
                    .font(.body)
                    .padding(.leading, 28)
            }

            if let limit = limit, items.count > limit {
                Text("+ \(items.count - limit) more")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 28)
            }
        }
    }
}

/// List of clickable URLs with copy functionality
struct URLList: View {
    let urls: [String]
    @State private var copiedURL: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Header with Copy All button
            HStack(spacing: 8) {
                Image(systemName: "link")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 20)

                Text("Links")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                // Copy All button
                Button {
                    copyAllURLs()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                        Text("Copy All")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }
            }

            // URL items
            ForEach(Array(urls.enumerated()), id: \.offset) { index, urlString in
                URLRow(urlString: urlString, copiedURL: $copiedURL)
            }
        }
    }

    private func copyAllURLs() {
        let allURLs = urls.joined(separator: "\n")
        UIPasteboard.general.string = allURLs
        copiedURL = "all"

        // Reset after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if copiedURL == "all" {
                copiedURL = nil
            }
        }
    }
}

/// Single URL row with clickable link and copy button
struct URLRow: View {
    let urlString: String
    @Binding var copiedURL: String?

    private var displayText: String {
        if urlString.count > 50 {
            return String(urlString.prefix(50)) + "..."
        }
        return urlString
    }

    private var isCopied: Bool {
        copiedURL == urlString
    }

    var body: some View {
        HStack(spacing: 8) {
            // Clickable link
            Button {
                openURL()
            } label: {
                Text(displayText)
                    .font(.body)
                    .foregroundColor(.blue)
                    .underline()
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(PlainButtonStyle())

            // Copy button
            Button {
                copyURL()
            } label: {
                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                    .font(.caption)
                    .foregroundColor(isCopied ? .green : .secondary)
            }
        }
        .padding(.leading, 28)
    }

    private func openURL() {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }

    private func copyURL() {
        UIPasteboard.general.string = urlString
        copiedURL = urlString

        // Reset after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if copiedURL == urlString {
                copiedURL = nil
            }
        }
    }
}
