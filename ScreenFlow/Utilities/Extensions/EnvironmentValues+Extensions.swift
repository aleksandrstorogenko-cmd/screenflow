//
//  EnvironmentValues+Extensions.swift
//  ScreenFlow
//
//  Custom environment values for app-wide state management
//

import SwiftUI

/// Environment key for hiding tab bar
private struct HideTabBarKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var hideTabBar: Bool {
        get { self[HideTabBarKey.self] }
        set { self[HideTabBarKey.self] = newValue }
    }
}

