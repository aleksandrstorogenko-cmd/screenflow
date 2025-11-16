//
//  EventInfoCard.swift
//  ScreenFlow
//
//  Card displaying extracted event information
//

import SwiftUI

/// Card showing event details (styled like LinksSection)
struct EventInfoCard: View {
    let data: ExtractedData

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header (matching LinksSection style)
            HStack(alignment: .firstTextBaseline) {
                Text("Event")
                    .font(.system(size: 20))
                    .fontWeight(.semibold)
                    .foregroundColor(Color(.systemGray))

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)

            // Event details card
            VStack(alignment: .leading, spacing: 12) {
                if let name = data.eventName {
                    DetailRow(icon: "ticket", label: "Event", value: name)
                }

                if let date = data.eventDate {
                    DetailRow(icon: "clock", label: "Date", value: formatDate(date))
                }

                if let location = data.eventLocation {
                    DetailRow(icon: "location", label: "Location", value: location)
                }

                if let description = data.eventDescription {
                    DetailRow(icon: "text.alignleft", label: "Description", value: description)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .cornerRadius(24)
            .padding(.horizontal, 16)
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
        .padding(.top, 8)
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

/// Reusable detail row
struct DetailRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.body)
            }
        }
    }
}
