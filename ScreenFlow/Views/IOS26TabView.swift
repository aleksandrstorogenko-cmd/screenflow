import SwiftUI
import SwiftData
import Combine
import UIKit

@available(iOS 26, *)
struct IOS26TabView: View {
    @State private var selectedTab:Int = 0
    @State private var isHidden: Bool = false

    var body: some View {
        TabView(selection: $selectedTab) {
            ScreenshotListView()
                .tabItem { Label("Inbox", systemImage: "tray.fill") }
                .toolbar(isHidden ? .hidden : .visible, for: .tabBar)
                .tag(0)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
                .tag(1)
        }
//        .onReceive(NavigationNotificationService.shared.receiveHideTabBarNotification()) { _ in
//            isHidden = true
//        }
//        .onReceive(NavigationNotificationService.shared.receiveShowTabBarNotification()) { _ in
//            isHidden = false
//        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .toolbarBackground(.regularMaterial, for: .tabBar)
        .toolbarBackgroundVisibility(.visible, for: .tabBar)
    }
}



//    .toolbar(.hidden, for: .bottomBar)
