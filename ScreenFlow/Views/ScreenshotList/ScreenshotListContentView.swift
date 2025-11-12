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
        List(selection: $selectedScreenshots) {
            ForEach(Array(screenshots.enumerated()), id: \.element.id) { index, screenshot in
                NavigationLink(value: screenshot) {
                    ScreenshotRowView(screenshot: screenshot)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        onDelete(screenshot)
                    } label: {
                        Image(systemName: "trash")
                    }
                }
                .onAppear {
                    // Load more when reaching near the end
                    if index == screenshots.count - 5 {
                        onLoadMore()
                    }
                }
            }
        }
        .listStyle(.plain)
        .background(Color.white)
        .scrollContentBackground(.hidden)
        .navigationDestination(for: Screenshot.self) { screenshot in
            ScreenshotDetailView(
                screenshot: screenshot,
                allScreenshots: screenshots
            )
        }
    }
}
