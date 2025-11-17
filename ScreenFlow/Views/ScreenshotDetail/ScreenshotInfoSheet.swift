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
    @Binding var currentDetent: PresentationDetent

    @Environment(\.modelContext) private var modelContext
    @State private var isRefreshing = false
    @State private var hasTriggeredInitialParsing = false

    private var currentScreenshot: Screenshot? {
        allScreenshots[safe: currentIndex]
    }

    var body: some View {
        NavigationStack {
            ZStack {
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

                            // Show loading state or extracted data
                            if isRefreshing {
                                VStack(spacing: 16) {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .scaleEffect(1.2)
                                    Text("Analyzing screenshot...")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            } else if let extractedData = screenshot.extractedData {
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
            .navigationTitle("Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    // Only show refresh button when in large detent
                    if currentDetent == .large {
                        Button {
                            refreshScreenshotData()
                        } label: {
                            if isRefreshing {
                                ProgressView()
                                    .progressViewStyle(.circular)
                            } else {
                                Label("Refresh", systemImage: "arrow.clockwise")
                            }
                        }
                        .disabled(isRefreshing || currentScreenshot == nil)
                    }
                }
            }
            .onAppear {
                // Auto-trigger parsing if no extracted data exists
                if let screenshot = currentScreenshot,
                   screenshot.extractedData == nil,
                   !hasTriggeredInitialParsing {
                    hasTriggeredInitialParsing = true
                    refreshScreenshotData()
                }
            }
            .onChange(of: currentIndex) { oldValue, newValue in
                // Reset parsing flag when switching screenshots
                hasTriggeredInitialParsing = false
                // Auto-trigger parsing for new screenshot if needed
                if let screenshot = currentScreenshot,
                   screenshot.extractedData == nil {
                    hasTriggeredInitialParsing = true
                    refreshScreenshotData()
                }
            }
        }
    }

    // MARK: - Actions

    /// Refresh screenshot data by re-analyzing
    private func refreshScreenshotData() {
        guard let screenshot = currentScreenshot else { return }

        isRefreshing = true

        Task {
            await PhotoLibraryService.shared.reanalyzeScreenshot(
                for: screenshot,
                modelContext: modelContext
            )

            // Delay to ensure UI updates
            try? await Task.sleep(for: .milliseconds(500))

            await MainActor.run {
                isRefreshing = false
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
