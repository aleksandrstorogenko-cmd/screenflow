//
//  ScreenshotCardView.swift
//  ScreenFlow
//
//  Card view for displaying screenshot in masonry grid
//

import SwiftUI

/// Card view for displaying a screenshot in the masonry grid
struct ScreenshotCardView: View {
    /// Screenshot to display
    let screenshot: Screenshot

    /// SwiftData model context
    @Environment(\.modelContext) private var modelContext

    /// Full-size image state
    @State private var image: UIImage?

    /// Track if we're currently generating title
    @State private var isGeneratingTitle = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image container with reduced height
            Group {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    // Placeholder while loading
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay {
                            ProgressView()
                        }
                }
            }
            .frame(height: imageContainerHeight)
            .clipped()
            .padding(8)

            // Title overlay
            VStack(alignment: .leading, spacing: 6) {
                // Kind icon and title
                HStack(spacing: 6) {
                    if let kind = screenshot.kind {
                        Image(systemName: iconForKind(kind))
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }

                    Text(screenshot.title ?? screenshot.fileName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                }

                // Date
                Text(screenshot.creationDate.screenshotDateString)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.top, 4)
            .padding(.bottom, 12)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .onAppear {
            loadImage()
            generateTitleIfNeeded()
        }
    }

    /// Calculate reduced image container height (30% less than original aspect ratio)
    private var imageContainerHeight: CGFloat {
        let aspectRatio = CGFloat(screenshot.height) / CGFloat(screenshot.width)
        // Assuming column width is approximately 180 (based on typical device width)
        let baseHeight = 180 * aspectRatio
        return baseHeight * 0.7 // 30% reduction
    }

    /// Load image from photo library with appropriate size for grid
    private func loadImage() {
        PhotoLibraryService.shared.fetchThumbnail(
            for: screenshot,
            targetSize: CGSize(width: 600, height: 600)
        ) { loadedImage in
            image = loadedImage
        }
    }

    /// Generate title for screenshot if it doesn't have one
    private func generateTitleIfNeeded() {
        // Skip if already has a title or already generating
        guard screenshot.title == nil && !isGeneratingTitle else { return }

        isGeneratingTitle = true

        Task {
            await PhotoLibraryService.shared.generateTitleIfNeeded(
                for: screenshot,
                modelContext: modelContext
            )
            isGeneratingTitle = false
        }
    }

    /// Get SF Symbol icon for screenshot kind
    private func iconForKind(_ kind: String) -> String {
        switch kind {
        case "qr": return "qrcode"
        case "document": return "doc.text"
        case "link": return "link"
        case "receipt": return "receipt"
        case "businessCard": return "person.text.rectangle"
        case "chat": return "message"
        case "text": return "text.alignleft"
        case "photo": return "photo"
        default: return "doc"
        }
    }
}
