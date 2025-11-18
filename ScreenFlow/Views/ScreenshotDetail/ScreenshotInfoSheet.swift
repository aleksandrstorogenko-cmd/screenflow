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
    let isDeleting: Bool
    let onDelete: (Screenshot) -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var isRefreshing = false

    private var currentScreenshot: Screenshot? {
        allScreenshots[safe: currentIndex]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        if let screenshot = currentScreenshot {
                            // Metadata
                            MetadataSection(screenshot: screenshot)
                                .padding(.top, -40)

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
                    .animation(.easeInOut(duration: 0.3), value: currentDetent)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: currentDetent)
            .toolbar {
                // Only show toolbar when in large detent
                if currentDetent == .large {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            refreshScreenshotData()
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                        .disabled(isRefreshing || currentScreenshot == nil)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                } else {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(role: .destructive) {
                            if let screenshot = currentScreenshot {
                                onDelete(screenshot)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .tint(Color(.systemRed))
                        .disabled(isRefreshing || isDeleting || currentScreenshot == nil)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
            }
            .onChange(of: currentDetent) { oldValue, newValue in
                // Only trigger parsing when sheet is expanded to large
                // AND screenshot hasn't been parsed yet
                if newValue == .large,
                   let screenshot = currentScreenshot,
                   screenshot.extractedData == nil,
                   !isRefreshing {
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
            VStack(spacing: 8) {
                HStack {
                    Text("Details").font(.title).bold()
                    Spacer()
                }

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
