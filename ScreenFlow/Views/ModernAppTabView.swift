import SwiftUI
import SwiftData
import Combine
import UIKit

@available(iOS 26, *)
struct ModernAppTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ScreenshotListView()
                .tabItem { Label("Inbox", systemImage: "tray.fill") }
                .tag(0)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
                .tag(1)
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .toolbarBackground(.regularMaterial, for: .tabBar)
        .toolbarBackgroundVisibility(.visible, for: .tabBar)
    }
}
