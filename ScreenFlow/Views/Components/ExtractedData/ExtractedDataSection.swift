//
//  ExtractedDataSection.swift
//  ScreenFlow
//
//  Section displaying all extracted data from a screenshot
//

import SwiftUI

/// Section showing extracted information from screenshot
struct ExtractedDataSection: View {
    let data: ExtractedData

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            Text("Extracted Information")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top, 8)

            // Event info (if available)
            if hasEventData {
                EventInfoCard(data: data)
            }

            // Contact info (if available)
            if hasContactData {
                ContactInfoCard(data: data)
            }

            // General entities (if available)
            if hasGeneralEntities {
                EntitiesCard(data: data)
            }

            // Detected objects (if available)
            if !data.detectedObjects.isEmpty {
                DetectedObjectsCard(objects: data.detectedObjects)
            }

            // Full text preview (if available)
            if let text = data.fullText, !text.isEmpty {
                TextPreviewCard(text: text)
            }

            // No data message
            if !hasAnyData {
                Text("No additional information extracted")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
        }
    }

    // MARK: - Computed Properties

    private var hasEventData: Bool {
        data.eventName != nil || data.eventDate != nil || data.eventLocation != nil
    }

    private var hasContactData: Bool {
        data.contactName != nil
    }

    private var hasGeneralEntities: Bool {
        !data.urls.isEmpty || !data.emails.isEmpty || !data.phoneNumbers.isEmpty || !data.addresses.isEmpty
    }

    private var hasAnyData: Bool {
        hasEventData || hasContactData || hasGeneralEntities || !data.detectedObjects.isEmpty || (data.fullText != nil && !data.fullText!.isEmpty)
    }
}
