//
//  AIProcessingSettingsSection.swift
//  ScreenFlow
//
//  Toggle that enables AI-enhanced recognition with clear privacy messaging.
//

import SwiftUI

/// Settings card for enabling AI processing with helpful context.
struct AIProcessingSettingsSection: View {
    @Binding var isEnabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PROCESSING")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Use AI")
                            .font(.body)
                            .fontWeight(.semibold)
                        Text("Improve recognition with our AI model for more accurate summaries.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 12)

                    Toggle("", isOn: $isEnabled)
                        .labelsHidden()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

                Divider()
                    .padding(.leading, 20)

                VStack(alignment: .leading, spacing: 8) {
                    Label("Requires internet access", systemImage: "wifi")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Text("When enabled, screenshots are temporarily uploaded to our secure processing service. Disable if you prefer to keep every image on this device.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("AI processing may not be suitable for highly sensitive content.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Color(uiColor: .systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(Color(uiColor: .separator).opacity(0.35), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        }
    }
}

#Preview("AI processing settings") {
    AIProcessingSettingsSection(isEnabled: .constant(true))
        .padding()
        .background(Color(uiColor: .systemGroupedBackground))
}
