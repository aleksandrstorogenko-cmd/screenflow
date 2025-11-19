//
//  ScreenshotListContentView.swift
//  ScreenFlow
//
//  Main content view for displaying the list of screenshots
//

import SwiftUI
import SwiftData

/// View displaying the scrollable list of screenshots
struct MasonryScreenshotListView: View {
    /// Screenshots to display (paginated)
    let screenshots: [Screenshot]

    /// All screenshots for navigation (not paginated)
    let allScreenshots: [Screenshot]

    /// Indicates if pagination is currently loading next page
    let isLoadingMore: Bool

    /// Indicates if more items are available to load
    let canLoadMore: Bool

    /// Selected screenshots for bulk operations
    @Binding var selectedScreenshots: Set<Screenshot.ID>

    /// Callback when screenshot should be deleted
    let onDelete: (Screenshot) -> Void

    /// Callback when more items should be loaded
    let onLoadMore: () -> Void

    /// Edit mode state
    @Environment(\.editMode) private var editMode

    /// Whether we're in edit mode
    private var isEditMode: Bool {
        editMode?.wrappedValue.isEditing ?? false
    }

    var body: some View {
        ZStack {
            MasonryLayout(
                screenshots: screenshots,
                canLoadMore: canLoadMore,
                isLoadingMore: isLoadingMore,
                onLoadMore: onLoadMore
            ) { screenshot, isLastInColumn in
                if isEditMode {
                    ScreenshotCardView(
                        screenshot: screenshot, 
                        selectedScreenshots: $selectedScreenshots
                    )
                } else {
                    NavigationLink(value: screenshot) {
                        ScreenshotCardView(
                            screenshot: screenshot, 
                            selectedScreenshots: $selectedScreenshots
                        )
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
}
