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
    /// Screenshots to display
    let screenshots: [Screenshot]

    /// Selected screenshots for bulk operations
    @Binding var selectedScreenshots: Set<Screenshot.ID>

    /// Callback when screenshot should be deleted
    let onDelete: (Screenshot) -> Void

    /// Callback when more items should be loaded
    let onLoadMore: () -> Void

    var body: some View {
        MasonryLayout(screenshots: screenshots) { screenshot in
            NavigationLink(value: screenshot) {
                ScreenshotCardView(screenshot: screenshot)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .background(Color(.systemGroupedBackground))
        .navigationDestination(for: Screenshot.self) { screenshot in
            ScreenshotDetailView(
                screenshot: screenshot,
                allScreenshots: screenshots
            )
        }
    }
}
