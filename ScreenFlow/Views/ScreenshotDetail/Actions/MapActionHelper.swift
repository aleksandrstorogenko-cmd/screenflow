//
//  MapActionHelper.swift
//  ScreenFlow
//
//  Helper for map-related actions
//

import Foundation
import UIKit

/// Helper for opening locations in Maps
/// TODO: Refactor to use ActionExecutor service instead of inline implementation
struct MapActionHelper {

    /// Result of map action
    enum Result {
        case success
        case failure(title: String, message: String)
    }

    /// Open address in Maps
    static func openMap(from screenshot: Screenshot) -> Result {
        guard let extracted = screenshot.extractedData else {
            return .failure(title: "No Data Available", message: "This screenshot hasn't been analyzed yet")
        }

        let address = extracted.addresses.first ?? extracted.eventLocation ?? ""

        guard !address.isEmpty else {
            return .failure(title: "No Address Found", message: "No location or address found on this screenshot")
        }

        if let encoded = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: "http://maps.apple.com/?q=\(encoded)") {
            UIApplication.shared.open(url)
            return .success
        } else {
            return .failure(title: "Invalid Address", message: "Could not process the address")
        }
    }
}
