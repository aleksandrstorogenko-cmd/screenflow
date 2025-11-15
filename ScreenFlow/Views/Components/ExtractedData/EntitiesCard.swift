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
        VStack(alignment: .leading, spacing: 12) {
            // Header with Copy All button (styled like the example)
            HStack {
                Text("Links")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Spacer()

                // Copy All button (styled like "Clear" in the example)
                Button {
                    copyAllURLs()
                } label: {
                    Text(copiedURL == "all" ? "Copied!" : "Copy All")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
            }

            // URL items in a card
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(urls.enumerated()), id: \.offset) { index, urlString in
                    URLRow(urlString: urlString, copiedURL: $copiedURL)

                    // Divider between items (except for last item)
                    if index < urls.count - 1 {
                        Divider()
                            .padding(.leading, 12)
                    }
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 0.5)
            )
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
        HStack(spacing: 12) {
            // Icon
            Image(systemName: "link")
                .font(.body)
                .foregroundColor(.blue)
                .frame(width: 24)

            // Clickable link
            Button {
                openURL()
            } label: {
                Text(displayText)
                    .font(.body)
                    .foregroundColor(.blue)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(PlainButtonStyle())

            // Copy button
            Button {
                copyURL()
            } label: {
                Image(systemName: isCopied ? "checkmark.circle.fill" : "doc.on.doc")
                    .font(.body)
                    .foregroundColor(isCopied ? .green : .secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
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
