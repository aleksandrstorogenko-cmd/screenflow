//
//  DetectedObjectsCard.swift
//  ScreenFlow
//
//  Card displaying detected objects from object detection
//

import SwiftUI

/// Card showing detected objects in the screenshot
struct DetectedObjectsCard: View {
    let objects: [DetectedObject]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "eye")
                    .foregroundColor(.indigo)
                Text("Detected Objects")
                    .font(.headline)
            }

            // Objects list
            ForEach(Array(objects.enumerated()), id: \.offset) { index, object in
                ObjectRow(object: object)
            }

            if objects.isEmpty {
                Text("No objects detected")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

/// Row displaying a single detected object
struct ObjectRow: View {
    let object: DetectedObject

    var body: some View {
        HStack(spacing: 8) {
            // Confidence indicator
            Circle()
                .fill(confidenceColor)
                .frame(width: 8, height: 8)

            // Label
            Text(object.label)
                .font(.body)

            // Details (if available)
            if let details = object.details, !details.isEmpty {
                Text("(\(details))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Confidence percentage
            Text("\(Int(object.confidence * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var confidenceColor: Color {
        if object.confidence > 0.7 {
            return .green
        } else if object.confidence > 0.4 {
            return .orange
        } else {
            return .red
        }
    }
}
