//
//  MapActionHandler.swift
//  ScreenFlow
//
//  Handles map/location actions
//

import Foundation
import UIKit

/// Handles map and location actions
@MainActor
final class MapActionHandler {
    /// Execute map action
    func execute(_ action: SmartAction) async -> Bool {
        // Decode address
        guard let address = ActionDataDecoder.decodeString(action.actionData) else {
            print("Failed to decode address")
            return false
        }

        // URL encode the address
        guard let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            print("Failed to encode address")
            return false
        }

        // Create Maps URL
        let urlString = "maps://?address=\(encodedAddress)"
        guard let url = URL(string: urlString) else {
            print("Failed to create Maps URL")
            return false
        }

        // Open in Apple Maps
        if UIApplication.shared.canOpenURL(url) {
            await UIApplication.shared.open(url)
            print("Opened address in Maps: \(address)")
            return true
        } else {
            print("Cannot open Maps URL")
            return false
        }
    }
}
