//
//  ScreenshotCardView.swift
//  ScreenFlow
//
//  Card view for displaying screenshot in masonry grid
//

import SwiftUI
import SwiftData

/// Card view for displaying a screenshot in the masonry grid
struct ScreenshotCardView: View {
    /// Screenshot to display
    let screenshot: Screenshot

    /// Edit mode state
    @Environment(\.editMode) private var editMode

    /// SwiftData model context
    @Environment(\.modelContext) private var modelContext

    /// Selected screenshots for bulk operations
    @Binding var selectedScreenshots: Set<Screenshot.ID>

    /// Full-size image state
    @State private var image: UIImage?

    /// Whether this screenshot is selected
    private var isSelected: Bool {
        selectedScreenshots.contains(screenshot.id)
    }

    /// Whether we're in edit mode
    private var isEditMode: Bool {
        editMode?.wrappedValue.isEditing ?? false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image container with reduced height
            ZStack(alignment: .bottomTrailing) {
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
                .cornerRadius(26)

                // Checkbox overlay in edit mode
                if isEditMode {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(isSelected ? .blue : .white)
                        .background(
                            Circle()
                                .fill(isSelected ? Color.white : Color.black.opacity(0.3))
                                .frame(width: 28, height: 28)
                        )
                        .padding(12)
                }
            }
            .padding(8)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .contentShape(RoundedRectangle(cornerRadius: 26))
        .if(isEditMode) { view in
            view.onTapGesture {
                toggleSelection()
            }
        }
        .onAppear {
            loadImage()
        }
    }

    /// Toggle selection state
    private func toggleSelection() {
        if selectedScreenshots.contains(screenshot.id) {
            selectedScreenshots.remove(screenshot.id)
        } else {
            selectedScreenshots.insert(screenshot.id)
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
}
