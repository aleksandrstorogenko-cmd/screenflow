//
//  MainTabView.swift
//  ScreenFlow
//
//  Main tab navigation view with Inbox and Settings tabs
//

import SwiftUI

/// Main tab view with bottom navigation
struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Inbox Tab
            ScreenshotListView()
                .tabItem {
                    Label("Inbox", systemImage: "tray.fill")
                }
                .tag(0)

            // Settings Tab
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(1)
        }
        .applyTabBarStyle()
    }
}

// MARK: - Tab Bar Styling

extension View {
    /// Applies conditional tab bar styling based on iOS version
    /// - iOS 26+: Liquid glass effect
    /// - iOS 18-25: Transparent ultra-thin material
    @ViewBuilder
    func applyTabBarStyle() -> some View {
        if #available(iOS 26, *) {
            // Liquid glass effect for iOS 26+
            self
                .toolbarBackground(.regularMaterial, for: .tabBar)
                .toolbarBackgroundVisibility(.visible, for: .tabBar)
        } else {
            // Transparent ultra-thin material for iOS 18-25
            self
                .toolbarBackground(.ultraThinMaterial, for: .tabBar)
                .toolbarBackgroundVisibility(.visible, for: .tabBar)
        }
    }
}

#Preview {
    MainTabView()
}
