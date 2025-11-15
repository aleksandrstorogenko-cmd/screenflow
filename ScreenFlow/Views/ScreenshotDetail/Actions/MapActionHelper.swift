//
//  MapActionHelper.swift
//  ScreenFlow
//
//  Helper for map-related actions using ActionExecutor
//

import Foundation

/// Helper for opening locations in Maps
@MainActor
struct MapActionHelper {

    /// Result of map action
    enum Result {
        case success
        case failure(title: String, message: String)
    }

    /// Open address in Maps using ActionExecutor
    static func openMap(from screenshot: Screenshot) async -> Result {
        guard let extracted = screenshot.extractedData else {
            return .failure(title: "No Data Available", message: "This screenshot hasn't been analyzed yet")
        }

        let address = extracted.addresses.first ?? extracted.eventLocation ?? ""

        guard !address.isEmpty else {
            return .failure(title: "No Address Found", message: "No location or address found on this screenshot")
        }

        // Create SmartAction
        let action = SmartActionFactory.createMapAction(address: address)

        // Execute using ActionExecutor
        let success = await ActionExecutor.shared.execute(action)

        if success {
            return .success
        } else {
            return .failure(title: "Failed to Open Map", message: "Could not open location in Maps")
        }
    }
}
