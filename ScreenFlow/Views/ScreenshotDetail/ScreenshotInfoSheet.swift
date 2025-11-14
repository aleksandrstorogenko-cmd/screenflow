//
//  ScreenshotInfoSheet.swift
//  ScreenFlow
//
//  Sheet displaying screenshot info, actions, and extracted data
//

import SwiftUI
import SwiftData

/// Sheet view showing screenshot metadata, actions, and extracted data
struct ScreenshotInfoSheet: View {
    let screenshot: Screenshot
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Thumbnail
                    ScreenshotThumbnailView(screenshot: screenshot)
                        .frame(height: 200)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .padding(.top)

                    // Metadata
                    MetadataSection(screenshot: screenshot)

                    Divider()
                        .padding(.horizontal)

                    // Smart Actions (if available)
                    if !screenshot.smartActions.isEmpty {
                        SmartActionsSection(actions: screenshot.smartActions, screenshot: screenshot)

                        Divider()
                            .padding(.horizontal)
                    }

                    // Extracted Data (if available)
                    if let extractedData = screenshot.extractedData {
                        ExtractedDataSection(data: extractedData)
                    }

                    Spacer(minLength: 20)
                }
            }
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

/// Metadata section showing basic screenshot info
struct MetadataSection: View {
    let screenshot: Screenshot

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Info")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 8) {
                MetadataRow(label: "File Name", value: screenshot.fileName)
                MetadataRow(label: "Date Created", value: formatDate(screenshot.creationDate))
                MetadataRow(label: "Size", value: "\(screenshot.width) × \(screenshot.height)")

                if let kind = screenshot.kind {
                    MetadataRow(label: "Type", value: kind.capitalized)
                }
            }
            .padding(.horizontal)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

/// Metadata row
struct MetadataRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
        }
    }
}

/// Thumbnail view for info sheet
struct ScreenshotThumbnailView: View {
    let screenshot: Screenshot
    @State private var thumbnailImage: UIImage?

    var body: some View {
        Group {
            if let image = thumbnailImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay {
                        ProgressView()
                    }
            }
        }
        .onAppear {
            loadThumbnail()
        }
    }

    private func loadThumbnail() {
        PhotoLibraryService.shared.fetchThumbnail(
            for: screenshot,
            targetSize: CGSize(width: 400, height: 400)
        ) { image in
            thumbnailImage = image
        }
    }
}
