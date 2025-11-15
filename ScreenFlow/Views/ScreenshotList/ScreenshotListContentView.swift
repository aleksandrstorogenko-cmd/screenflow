//
//  ScreenshotListContentView.swift
//  ScreenFlow
//
//  Main content view for displaying the list of screenshots
//

import SwiftUI
import SwiftData

/// View displaying the scrollable list of screenshots
struct ScreenshotListContentView: View {
    /// Screenshots to display (paginated)
    let screenshots: [Screenshot]

    /// All screenshots for navigation (not paginated)
    let allScreenshots: [Screenshot]

    /// Selected screenshots for bulk operations
    @Binding var selectedScreenshots: Set<Screenshot.ID>

    /// Callback when screenshot should be deleted
    let onDelete: (Screenshot) -> Void

    /// Callback when more items should be loaded
    let onLoadMore: () -> Void

    /// Edit mode state
    @Environment(\.editMode) private var editMode

    /// Loading state for pagination
    @State private var isLoadingMore = false

    /// Whether we're in edit mode
    private var isEditMode: Bool {
        editMode?.wrappedValue.isEditing ?? false
    }

    var body: some View {
        ZStack {
            MasonryLayout(screenshots: screenshots, onLoadMore: handleLoadMore) { screenshot, isLastInColumn in
                if isEditMode {
                    // In edit mode, just show the card without navigation
                    ScreenshotCardView(screenshot: screenshot, selectedScreenshots: $selectedScreenshots)
                } else {
                    // Normal mode with navigation
                    NavigationLink(value: screenshot) {
                        ScreenshotCardView(screenshot: screenshot, selectedScreenshots: $selectedScreenshots)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .background(Color(.systemGroupedBackground))
        }
        .navigationDestination(for: Screenshot.self) { screenshot in
            ScreenshotDetailView(
                screenshot: screenshot,
                allScreenshots: allScreenshots
            )
        }
    }

    /// Handle load more with debouncing
    private func handleLoadMore() {
        guard !isLoadingMore else { return }

        isLoadingMore = true
        onLoadMore()

        // Reset loading state after a short delay to prevent rapid firing
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            isLoadingMore = false
        }
    }
}
