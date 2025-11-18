//
//  MinimizableTabBar.swift
//  ScreenFlow
//
//  Custom tab bar that can minimize to a single button
//

import SwiftUI

/// Tab item configuration
struct TabItem: Identifiable {
    let id: Int
    let title: String
    let icon: String
}

/// Custom minimizable tab bar
struct MinimizableTabBar: View {
    /// Available tabs
    let tabs: [TabItem]

    /// Currently selected tab
    @Binding var selectedTab: Int

    /// Whether tab bar is minimized
    @Binding var isMinimized: Bool

    var body: some View {
        HStack(spacing: 0) {
            if isMinimized {
                // Minimized state - single button on the left
                minimizedButton
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            } else {
                // Full tab bar
                fullTabBar
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
            }
        }
        .padding(.horizontal, isMinimized ? 16 : 0)
        .padding(.vertical, 8)
        .background(tabBarBackground)
    }

    // MARK: - Subviews

    /// Minimized button showing selected tab
    private var minimizedButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isMinimized = false
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: currentTabIcon)
                    .font(.system(size: 20, weight: .medium))

                Text(currentTabTitle)
                    .font(.system(size: 16, weight: .semibold))

                Image(systemName: "chevron.up")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
            )
        }
        .buttonStyle(.plain)
    }

    /// Full tab bar with all tabs
    private var fullTabBar: some View {
        HStack(spacing: 0) {
            ForEach(tabs) { tab in
                tabButton(for: tab)
            }
        }
    }

    /// Individual tab button
    private func tabButton(for tab: TabItem) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedTab = tab.id
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 22, weight: selectedTab == tab.id ? .semibold : .regular))

                Text(tab.title)
                    .font(.system(size: 11, weight: selectedTab == tab.id ? .semibold : .regular))
            }
            .foregroundStyle(selectedTab == tab.id ? .primary : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    /// Tab bar background
    private var tabBarBackground: some View {
        Group {
            if #available(iOS 26, *) {
                RoundedRectangle(cornerRadius: isMinimized ? 0 : 0)
                    .fill(.regularMaterial)
            } else {
                RoundedRectangle(cornerRadius: isMinimized ? 0 : 0)
                    .fill(.ultraThinMaterial)
            }
        }
        .shadow(color: .black.opacity(0.05), radius: 8, y: -2)
    }

    // MARK: - Computed Properties

    /// Current tab icon
    private var currentTabIcon: String {
        tabs.first { $0.id == selectedTab }?.icon ?? "square.grid.2x2"
    }

    /// Current tab title
    private var currentTabTitle: String {
        tabs.first { $0.id == selectedTab }?.title ?? "Tab"
    }
}

#Preview("Normal Tab Bar") {
    VStack {
        Spacer()
        MinimizableTabBar(
            tabs: [
                TabItem(id: 0, title: "Inbox", icon: "tray.fill"),
                TabItem(id: 1, title: "Settings", icon: "gear")
            ],
            selectedTab: .constant(0),
            isMinimized: .constant(false)
        )
    }
}

#Preview("Minimized Tab Bar") {
    VStack {
        Spacer()
        MinimizableTabBar(
            tabs: [
                TabItem(id: 0, title: "Inbox", icon: "tray.fill"),
                TabItem(id: 1, title: "Settings", icon: "gear")
            ],
            selectedTab: .constant(0),
            isMinimized: .constant(true)
        )
    }
}
