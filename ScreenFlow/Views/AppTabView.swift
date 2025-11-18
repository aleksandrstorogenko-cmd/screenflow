//
//  AppTabView.swift
//  ScreenFlow
//
//  App tab navigation view with Inbox and Settings tabs
//

import SwiftUI

/// App tab view with bottom navigation that minimizes on scroll
struct AppTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        if #available(iOS 26, *) {
            // iOS 26+: Use standard tabBarMinimizeBehavior
            modernTabView
                .tabBarMinimizeBehavior(.onScrollDown)
        } else {
            // iOS 18-25: Use custom minimize behavior
            legacyTabView
        }
    }

    // MARK: - iOS 26+ Modern Tab View

    @available(iOS 26, *)
    private var modernTabView: some View {
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
        .toolbarBackground(.regularMaterial, for: .tabBar)
        .toolbarBackgroundVisibility(.visible, for: .tabBar)
    }

    // MARK: - iOS 18-25 Legacy Tab View

    private var legacyTabView: some View {
        LegacyMinimizableTabView(selectedTab: $selectedTab)
    }
}

// MARK: - Legacy Minimizable Tab View for iOS 18-25

/// Custom tab view with minimize behavior for iOS 18-25
struct LegacyMinimizableTabView: View {
    @Binding var selectedTab: Int

    /// Whether tab bar is minimized
    @State private var isTabBarMinimized = false

    /// Last scroll offset for direction detection
    @State private var lastScrollOffset: CGFloat = 0

    /// Available tabs
    private let tabs = [
        TabItem(id: 0, title: "Inbox", icon: "tray.fill"),
        TabItem(id: 1, title: "Settings", icon: "gear")
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content area
            TabContentView(selectedTab: selectedTab)
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                    handleScrollOffset(offset)
                }

            // Custom minimizable tab bar
            MinimizableTabBar(
                tabs: tabs,
                selectedTab: $selectedTab,
                isMinimized: $isTabBarMinimized
            )
            .onChange(of: selectedTab) { _, _ in
                // Reset minimize state when switching tabs
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isTabBarMinimized = false
                }
            }
        }
        .edgesIgnoringSafeArea(.bottom)
    }

    // MARK: - Methods

    /// Handle scroll offset changes to minimize/maximize tab bar
    private func handleScrollOffset(_ offset: CGFloat) {
        let scrollDelta = offset - lastScrollOffset

        // Threshold for triggering minimize/maximize (in points)
        let threshold: CGFloat = 50

        if scrollDelta < -threshold && !isTabBarMinimized {
            // Scrolling down - minimize
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isTabBarMinimized = true
            }
        } else if scrollDelta > threshold && isTabBarMinimized {
            // Scrolling up - maximize
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isTabBarMinimized = false
            }
        }

        lastScrollOffset = offset
    }
}

// MARK: - Tab Content View

/// Container for tab content views
struct TabContentView: View {
    let selectedTab: Int

    var body: some View {
        ZStack {
            // Inbox Tab
            ScreenshotListView()
                .opacity(selectedTab == 0 ? 1 : 0)
                .zIndex(selectedTab == 0 ? 1 : 0)

            // Settings Tab
            SettingsView()
                .opacity(selectedTab == 1 ? 1 : 0)
                .zIndex(selectedTab == 1 ? 1 : 0)
        }
    }
}

#Preview {
    AppTabView()
}
