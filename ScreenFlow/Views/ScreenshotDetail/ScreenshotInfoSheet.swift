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
    let allScreenshots: [Screenshot]
    @Binding var currentIndex: Int

    private var currentScreenshot: Screenshot? {
        allScreenshots[safe: currentIndex]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let screenshot = currentScreenshot {
                    // Metadata
                    MetadataSection(screenshot: screenshot)

                    Divider()
                        .padding(.horizontal)
                        .padding(.top, 10)

                    // Links Section (if available) - Separate from Extracted Data
                    if let extractedData = screenshot.extractedData, !extractedData.urls.isEmpty {
                        LinksSection(urls: extractedData.urls)
                            .padding(.top, 8)

                        Divider()
                            .padding(.horizontal)
                            .padding(.top, 10)
                    }

                    // Extracted Data (if available)
                    if let extractedData = screenshot.extractedData {
                        ExtractedDataSection(data: extractedData)
                    }
                } else {
                    Text("No screenshot selected")
                        .foregroundColor(.secondary)
                        .padding()
                }

                Spacer(minLength: 20)
            }
            .padding(.top)
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
                .lineLimit(1)
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
