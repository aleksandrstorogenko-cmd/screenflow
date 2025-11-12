//
//  Date+Extensions.swift
//  ScreenFlow
//
//  Date formatting extensions
//

import Foundation

extension Date {
    /// Format date as a readable string for screenshot metadata
    /// Format: "MMM dd, yyyy • h:mm a" (e.g., "Nov 11, 2025 • 3:45 PM")
    var screenshotDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy • h:mm a"
        return formatter.string(from: self)
    }
}
