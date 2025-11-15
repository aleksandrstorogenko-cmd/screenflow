//
//  BottomScrollSheet.swift
//  ScreenFlow
//
//  Created by Oleksandr Storozhenko on 11/14/25.
//


//
//  ScreenshotSheetContainer.swift
//  ScreenFlow
//
//  Reusable container that shows a fullscreen background view
//  with a bottom sheet-like scrollable content.
//

import SwiftUI

/// A reusable container that displays:
/// - a fullscreen background view (e.g. screenshot)
/// - a bottom sheet-like scrollable content that initially peeks from the bottom
///
/// Usage:
///
/// BottomScrollSheet(
///     visibleHeight: 100
/// ) {
///     ScreenshotImageView(screenshot: screenshot)
/// } sheetContent: {
///     ScreenshotInfoSheet(screenshot: screenshot)
/// }
///
struct BottomScrollSheet<Background: View, SheetContent: View>: View {
    /// How much of the sheet is visible when at rest (peeking from the bottom).
    let visibleHeight: CGFloat

    /// Background view (usually a fullscreen image).
    let background: () -> Background

    /// Sheet content shown as a scrollable card from the bottom.
    let sheetContent: () -> SheetContent

    init(
        visibleHeight: CGFloat = 100,
        @ViewBuilder background: @escaping () -> Background,
        @ViewBuilder sheetContent: @escaping () -> SheetContent
    ) {
        self.visibleHeight = visibleHeight
        self.background = background
        self.sheetContent = sheetContent
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Fullscreen background
                background()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .ignoresSafeArea()

                // Sheet-like scroll that starts near the bottom
                ScrollView(showsIndicators: true) {
                    VStack(spacing: 0) {
                        // Transparent spacer to push the sheet down
                        Color.clear
                            .frame(height: geo.size.height - visibleHeight)

                        // Sheet content styled as a card
                        sheetContent()
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    }
                }
            }
            .ignoresSafeArea()
        }
    }
}
