//
//  View+Extensions.swift
//  ScreenFlow
//
//  Navigation sub-title if IOS 26+
//

import SwiftUI


extension View {
    @ViewBuilder
    func navigationSubtitleIfAvailable(_ text: String) -> some View {
        if #available(iOS 26.0, *) {
            self.navigationSubtitle(text)
        } else {
            self
        }
    }
}
