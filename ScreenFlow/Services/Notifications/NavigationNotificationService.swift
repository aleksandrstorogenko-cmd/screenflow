//
//  ProjectNotificationService.swift
//  ScreenFlow
//
//  Created by Oleksandr Storozhenko on 11/23/25.
//
import SwiftUI


@MainActor
final class NavigationNotificationService: BaseNotificationService, @unchecked Sendable {
    static let shared = NavigationNotificationService()

    // Project created notification


    func sendHideTabBarNotification() {
        sendNotification("HideTabBar")
    }


    func receiveHideTabBarNotification() -> NotificationCenter.Publisher {
        recieveNotification("HideTabBar")
    }


    func sendShowTabBarNotification() {
        sendNotification("ShowTabBar")
    }

    func receiveShowTabBarNotification() -> NotificationCenter.Publisher {
        recieveNotification("ShowTabBar")
    }
}
