//
//  URLActionHelper.swift
//  ScreenFlow
//
//  Helper for URL-related actions
//

import Foundation
import UIKit

/// Helper for opening URLs
/// TODO: Refactor to use ActionExecutor service instead of inline implementation
struct URLActionHelper {

    /// Result of URL action
    enum Result {
        case success
        case failure(title: String, message: String)
    }

    /// Open a URL from screenshot
    static func openURL(from screenshot: Screenshot) -> Result {
        guard let extracted = screenshot.extractedData else {
            return .failure(title: "No Data Available", message: "This screenshot hasn't been analyzed yet")
        }

        guard let firstURL = extracted.urls.first else {
            return .failure(title: "No URL Found", message: "No website link found on this screenshot")
        }

        guard let url = URL(string: firstURL) else {
            return .failure(title: "Invalid URL", message: "The URL format is invalid")
        }

        UIApplication.shared.open(url)
        return .success
    }
}
