//
//  MasonryLayout.swift
//  ScreenFlow
//
//  Masonry/waterfall layout for displaying screenshots in a 2-column grid
//

import SwiftUI

/// A 2-column masonry layout that arranges items with varying heights
struct MasonryLayout<Content: View>: View {
    /// Items to display
    let screenshots: [Screenshot]

    /// Spacing between items
    let spacing: CGFloat = 8

    /// Whether we can load more content
    let canLoadMore: Bool

    /// Whether a page request is already in progress
    let isLoadingMore: Bool

    /// Callback when more items should be loaded
    let onLoadMore: () -> Void

    /// Content builder for each item
    @ViewBuilder let content: (Screenshot, Bool) -> Content

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Scroll offset tracker at the top
                    Color.clear
                        .frame(height: 0)
                        .readScrollOffset(coordinateSpace: "masonryScroll")

                    HStack(alignment: .top, spacing: spacing) {
                        LazyVStack(spacing: spacing) {
                            ForEach(Array(leftColumnItems.enumerated()), id: \.element.id) { index, screenshot in
                                content(screenshot, isLastItem(screenshot, in: leftColumnItems))
                                    .onAppear {
                                        checkAndLoadMore(screenshot: screenshot, index: index, columnItems: leftColumnItems)
                                    }
                            }
                        }

                        LazyVStack(spacing: spacing) {
                            ForEach(Array(rightColumnItems.enumerated()), id: \.element.id) { index, screenshot in
                                content(screenshot, isLastItem(screenshot, in: rightColumnItems))
                                    .onAppear {
                                        checkAndLoadMore(screenshot: screenshot, index: index, columnItems: rightColumnItems)
                                    }
                            }
                        }
                    }
                    .padding(.horizontal, spacing)
                    .padding(.top, spacing)

                    // Loading indicator at the bottom when loading more
                    if isLoadingMore {
                        HStack {
                            Spacer()
                            ProgressView()
                                .padding(.vertical, 20)
                            Spacer()
                        }
                    }
                }
            }
            .coordinateSpace(name: "masonryScroll")
        }
    }

    /// Items for the left column
    private var leftColumnItems: [Screenshot] {
        distributeItems().0
    }

    /// Items for the right column
    private var rightColumnItems: [Screenshot] {
        distributeItems().1
    }

    /// Check if we should load more items
    private func checkAndLoadMore(screenshot: Screenshot, index: Int, columnItems: [Screenshot]) {
        guard canLoadMore else { return }
        guard !isLoadingMore else { return }

        // Load more when we're 5 items from the end of either column
        if index >= columnItems.count - 3 {
            // Also check if this screenshot is near the end of the total list
            if let totalIndex = screenshots.firstIndex(where: { $0.id == screenshot.id }),
               totalIndex >= screenshots.count - 5 {
                onLoadMore()
            }
        }
    }

    /// Check if this is the last item in the column
    private func isLastItem(_ screenshot: Screenshot, in column: [Screenshot]) -> Bool {
        column.last?.id == screenshot.id
    }

    /// Distribute screenshots between two columns to balance heights
    private func distributeItems() -> ([Screenshot], [Screenshot]) {
        var leftColumn: [Screenshot] = []
        var rightColumn: [Screenshot] = []
        var leftHeight: CGFloat = 0
        var rightHeight: CGFloat = 0

        for screenshot in screenshots {
            // Calculate relative height based on aspect ratio
            let aspectRatio = CGFloat(screenshot.height) / CGFloat(screenshot.width)

            // Add to the shorter column
            if leftHeight <= rightHeight {
                leftColumn.append(screenshot)
                leftHeight += aspectRatio
            } else {
                rightColumn.append(screenshot)
                rightHeight += aspectRatio
            }
        }

        return (leftColumn, rightColumn)
    }
}
