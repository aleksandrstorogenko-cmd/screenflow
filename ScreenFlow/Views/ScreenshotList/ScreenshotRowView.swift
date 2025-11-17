//
//  ScreenshotRowView.swift
//  ScreenFlow
//
//  Row view component for displaying screenshot in list
//

import SwiftUI
import SwiftData

/// Row view for displaying a single screenshot in the list
struct ScreenshotRowView: View {
    /// Screenshot to display
    let screenshot: Screenshot

    /// SwiftData model context
    @Environment(\.modelContext) private var modelContext

    /// Thumbnail image state
    @State private var thumbnailImage: UIImage?

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail on the left
            Group {
                if let image = thumbnailImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    // Placeholder while loading
                    Color.gray.opacity(0.3)
                }
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Text content
            VStack(alignment: .leading, spacing: 4) {
                // Generated title or file name as fallback
                HStack(spacing: 6) {
                    // Kind icon
                    if let kind = screenshot.kind {
                        Image(systemName: iconForKind(kind))
                            .font(.caption)
                            .foregroundColor(.blue)
                    }

                    Text(screenshot.title ?? screenshot.fileName)
                        .font(.body)
                        .lineLimit(1)
                }

                // Date and time as subtitle
                Text(screenshot.creationDate.screenshotDateString)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .onAppear {
            loadThumbnail()
        }
    }

    /// Load thumbnail image from photo library
    private func loadThumbnail() {
        PhotoLibraryService.shared.fetchThumbnail(for: screenshot) { image in
            thumbnailImage = image
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
