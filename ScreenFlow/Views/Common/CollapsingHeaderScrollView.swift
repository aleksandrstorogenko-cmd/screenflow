//
//  CollapsingHeaderScrollView.swift
//  ScreenFlow
//
//  Created by Oleksandr Storozhenko on 11/14/25.
//


import SwiftUI

/// A scroll view with a collapsing/stretchy header.
///
/// Behavior:
/// - When scrolling up, the header shrinks and slightly moves up, but never disappears.
/// - When pulling down, the header expands and "stretches" back.
///
/// Example usage:
///
/// CollapsingHeaderScrollView(
///     maxHeaderHeight: 260,
///     minHeaderHeight: 120
/// ) {
///     Image("meerkats")
///         .resizable()
///         .scaledToFill()
/// } content: {
///     VStack(spacing: 16) {
///         ForEach(0..<30) { i in
///             RoundedRectangle(cornerRadius: 26)
///                 .fill(Color(.secondarySystemBackground))
///                 .frame(height: 60)
///                 .overlay(Text("Item #\(i + 1)"))
///                 .padding(.horizontal)
///         }
///         .padding(.top, 16)
///     }
/// }
/// .ignoresSafeArea(edges: .top)
///
struct CollapsingHeaderScrollView<Header: View, Content: View>: View {
    private let maxHeaderHeight: CGFloat
    private let minHeaderHeight: CGFloat
    private let showsIndicators: Bool
    private let header: () -> Header
    private let content: () -> Content

    /// - Parameters:
    ///   - maxHeaderHeight: Initial height of the header (image when view first appears).
    ///   - minHeaderHeight: Minimum height when scrolled up (header won't shrink below this).
    ///   - showsIndicators: Whether to show the standard scroll indicators.
    ///   - header: The header view (usually an image).
    ///   - content: The main content below the header.
    init(
        maxHeaderHeight: CGFloat = 260,
        minHeaderHeight: CGFloat = 120,
        showsIndicators: Bool = false,
        @ViewBuilder header: @escaping () -> Header,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.maxHeaderHeight = maxHeaderHeight
        self.minHeaderHeight = minHeaderHeight
        self.showsIndicators = showsIndicators
        self.header = header
        self.content = content
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: showsIndicators) {
            // HEADER
            GeometryReader { geo in
                let offset = geo.frame(in: .named("CollapsingHeaderScrollView")).minY
                let headerHeight = computeHeaderHeight(offset: offset)
                let scale = computeScale(offset: offset)

                header()
                    .frame(maxWidth: .infinity)
                    .frame(height: headerHeight)
                    .clipped()
                    .scaleEffect(scale, anchor: .center)
                    .offset(y: offset < 0 ? offset * 0.2 : 0)
            }
            .frame(height: maxHeaderHeight)

            // CONTENT
            content()
        }
        .coordinateSpace(name: "CollapsingHeaderScrollView")
    }

    // MARK: - Header height & scale logic

    private func computeHeaderHeight(offset: CGFloat) -> CGFloat {
        if offset < 0 {
            // Scrolling up: collapse header but keep at least minHeaderHeight
            let collapsedHeight = maxHeaderHeight + offset   // offset is negative
            return max(collapsedHeight, minHeaderHeight)
        } else {
            // Pulling down (overscroll): stretch header
            return maxHeaderHeight + offset
        }
    }

    private func computeScale(offset: CGFloat) -> CGFloat {
        // Apply shrink only when scrolling up (offset < 0)
        guard offset < 0 else { return 1.0 }

        let range = max(maxHeaderHeight - minHeaderHeight, 1)
        let collapseAmount = min(-offset, range) // 0...range
        let progress = collapseAmount / range
        let minScale: CGFloat = 0.9

        // Smoothly interpolate from 1.0 down to 0.9 as we collapse
        return 1.0 - (1.0 - minScale) * progress
    }
}
