import SwiftUI

struct LegacyAppTabView: View {
    @State private var selectedTab = 0
    @State private var isTabBarMinimized = false
    @State private var lastScrollOffset: CGFloat = 0

    private let tabs = [
        TabItem(id: 0, title: "Inbox", icon: "tray.fill"),
        TabItem(id: 1, title: "Settings", icon: "gear")
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            TabContentView(
                selectedTab: selectedTab
            )
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                handleScrollOffset(offset)
            }

            MinimizableTabBar(
                tabs: tabs,
                selectedTab: $selectedTab,
                isMinimized: $isTabBarMinimized
            )
            .onChange(of: selectedTab) { _, _ in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isTabBarMinimized = false
                }
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .edgesIgnoringSafeArea(.bottom)
    }

    private func handleScrollOffset(_ offset: CGFloat) {
        let scrollDelta = offset - lastScrollOffset
        let threshold: CGFloat = 50

        if scrollDelta < -threshold && !isTabBarMinimized {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isTabBarMinimized = true
            }
        } else if scrollDelta > threshold && isTabBarMinimized {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isTabBarMinimized = false
            }
        }

        lastScrollOffset = offset
    }
}

private struct TabContentView: View {
    let selectedTab: Int

    var body: some View {
        ZStack {
            ScreenshotListView()
                .opacity(selectedTab == 0 ? 1 : 0)
                .zIndex(selectedTab == 0 ? 1 : 0)

            SettingsView()
                .opacity(selectedTab == 1 ? 1 : 0)
                .zIndex(selectedTab == 1 ? 1 : 0)
        }
    }
}

