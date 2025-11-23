//
//  BaseNotificationService.swift
//  ScreenFlow
//
//  Created by Oleksandr Storozhenko on 11/23/25.
//
import SwiftUI


@MainActor
class BaseNotificationService: NotificationCenter, @unchecked Sendable {


    func sendNotification(_ notficationName: String) {
        NotificationCenter.default.post(name: NSNotification.Name(notficationName), object: nil)
    }


    func recieveNotification(_ notficationName: String) -> NotificationCenter.Publisher {
        NotificationCenter.default.publisher(for: NSNotification.Name(notficationName))
    }

}
