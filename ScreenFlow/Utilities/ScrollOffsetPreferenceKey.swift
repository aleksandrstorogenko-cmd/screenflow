//
//  ScrollOffsetPreferenceKey.swift
//  ScreenFlow
//
//  Preference key for tracking scroll offset
//

import SwiftUI

/// Preference key to track scroll offset
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/// View extension to track scroll offset
extension View {
    /// Reads scroll offset and reports it via preference key
    func readScrollOffset(coordinateSpace: String = "scroll") -> some View {
        background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: ScrollOffsetPreferenceKey.self,
                    value: proxy.frame(in: .named(coordinateSpace)).minY
                )
            }
        )
    }
}
