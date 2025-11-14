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

    /// Content builder for each item
    @ViewBuilder let content: (Screenshot) -> Content

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                HStack(alignment: .top, spacing: spacing) {
                    LazyVStack(spacing: spacing) {
                        ForEach(leftColumnItems, id: \.id) { screenshot in
                            content(screenshot)
                        }
                    }

                    LazyVStack(spacing: spacing) {
                        ForEach(rightColumnItems, id: \.id) { screenshot in
                            content(screenshot)
                        }
                    }
                }
                .padding(.horizontal, spacing)
                .padding(.top, spacing)
            }
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
