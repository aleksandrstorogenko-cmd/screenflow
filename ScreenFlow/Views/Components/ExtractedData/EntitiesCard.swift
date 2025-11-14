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
            }

            // URLs
            if !data.urls.isEmpty {
                EntityList(icon: "link", label: "Links", items: data.urls.map { truncate($0, length: 50) })
            }

            // Emails
            if !data.emails.isEmpty {
                EntityList(icon: "envelope", label: "Emails", items: data.emails)
            }

            // Phone numbers
            if !data.phoneNumbers.isEmpty {
                EntityList(icon: "phone", label: "Phones", items: data.phoneNumbers)
            }

            // Addresses
            if !data.addresses.isEmpty {
                EntityList(icon: "mappin.and.ellipse", label: "Addresses", items: data.addresses)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
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

            ForEach(items.prefix(5), id: \.self) { item in
                Text(item)
                    .font(.body)
                    .padding(.leading, 28)
            }

            if items.count > 5 {
                Text("+ \(items.count - 5) more")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 28)
            }
        }
    }
}
