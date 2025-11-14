//
//  EventInfoCard.swift
//  ScreenFlow
//
//  Card displaying extracted event information
//

import SwiftUI

/// Card showing event details
struct EventInfoCard: View {
    let data: ExtractedData

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.orange)
                Text("Event")
                    .font(.headline)
            }

            // Event details
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
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
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
