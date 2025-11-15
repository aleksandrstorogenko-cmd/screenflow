//
//  BottomSheet.swift
//  ScreenFlow
//
//  Created by Oleksandr Storozhenko on 11/14/25.
//


import SwiftUI

/// Reusable bottom sheet with a collapsed and expanded height.
/// Shows only `minHeight` at the bottom initially.
/// Drag up to expand, drag down to collapse. Content inside is scrollable.
struct BottomSheet<Content: View>: View {
    let minHeight: CGFloat       // Visible height when collapsed (e.g. 100)
    let maxHeight: CGFloat       // Height when fully expanded
    let content: () -> Content   // Sheet content

    @State private var currentHeight: CGFloat
    @GestureState private var dragOffset: CGFloat = 0

    init(
        minHeight: CGFloat,
        maxHeight: CGFloat,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        self.content = content
        _currentHeight = State(initialValue: minHeight)
    }

    var body: some View {
        let drag = DragGesture()
            .updating($dragOffset) { value, state, _ in
                state = value.translation.height
            }
            .onEnded { value in
                let newHeight = currentHeight - value.translation.height
                let clamped = min(max(newHeight, minHeight), maxHeight)
                let middle = (minHeight + maxHeight) / 2

                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    // Snap to collapsed or expanded depending on where user released
                    currentHeight = clamped < middle ? maxHeight : minHeight
                }
            }

        VStack(spacing: 0) {
            // Small drag handle
            Capsule()
                .frame(width: 40, height: 5)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
                .padding(.bottom, 8)

            // Scrollable content inside the sheet
            ScrollView(showsIndicators: true) {
                content()
                    .padding(.horizontal)
                    .padding(.bottom, 16)
            }
        }
        .frame(height: sheetHeight)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(radius: 10)
        .frame(maxHeight: .infinity, alignment: .bottom)
        .gesture(drag)
    }

    /// Current sheet height during drag.
    private var sheetHeight: CGFloat {
        let proposed = currentHeight - dragOffset
        return max(minHeight, min(maxHeight, proposed))
    }
}
