//
//  URLActionHelper.swift
//  ScreenFlow
//
//  Helper for URL-related actions using ActionExecutor
//

import Foundation

/// Helper for opening URLs
@MainActor
struct URLActionHelper {

    /// Result of URL action
    enum Result {
        case success
        case failure(title: String, message: String)
    }

    /// Open a URL from screenshot using ActionExecutor
    static func openURL(from screenshot: Screenshot) async -> Result {
        guard let extracted = screenshot.extractedData else {
            return .failure(title: "No Data Available", message: "This screenshot hasn't been analyzed yet")
        }

        guard let firstURL = extracted.urls.first else {
            return .failure(title: "No URL Found", message: "No website link found on this screenshot")
        }

        // Create SmartAction
        let action = SmartActionFactory.createLinkAction(url: firstURL)

        // Execute using ActionExecutor
        let success = await ActionExecutor.shared.execute(action)

        if success {
            return .success
        } else {
            return .failure(title: "Failed to Open URL", message: "Could not open the link")
        }
    }
}
