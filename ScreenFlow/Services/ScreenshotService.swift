//
//  ScreenshotService.swift
//  ScreenFlow
//
//  Service for managing screenshot filtering and operations
//

import Foundation
import SwiftData

/// Service responsible for screenshot filtering and management operations
@MainActor
final class ScreenshotService {
    /// Singleton instance
    static let shared = ScreenshotService()

    /// Photo library service dependency
    private let photoLibraryService = PhotoLibraryService.shared

    private init() {}

    // MARK: - Filtering

    /// Filter screenshots based on search text and date filter
    /// - Parameters:
    ///   - screenshots: Array of all screenshots
    ///   - searchText: Search query string
    ///   - showTodayOnly: Whether to filter for today's screenshots only
    ///   - limit: Maximum number of items to return (for pagination)
    /// - Returns: Filtered array of screenshots
    func filterScreenshots(
        _ screenshots: [Screenshot],
        searchText: String,
        showTodayOnly: Bool,
        limit: Int
    ) -> [Screenshot] {
        var filtered = screenshots

        // Apply today's filter if enabled
        if showTodayOnly {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            filtered = filtered.filter { screenshot in
                calendar.isDate(screenshot.creationDate, inSameDayAs: today)
            }
        }

        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { screenshot in
                screenshot.fileName.localizedCaseInsensitiveContains(searchText) ||
                screenshot.title?.localizedCaseInsensitiveContains(searchText) == true
            }
        }

        // Apply pagination limit
        return Array(filtered.prefix(limit))
    }

    /// Get total count of filtered screenshots (without pagination limit)
    /// - Parameters:
    ///   - screenshots: Array of all screenshots
    ///   - searchText: Search query string
    ///   - showTodayOnly: Whether to filter for today's screenshots only
    /// - Returns: Total count of filtered screenshots
    func getFilteredCount(
        _ screenshots: [Screenshot],
        searchText: String,
        showTodayOnly: Bool
    ) -> Int {
        var filtered = screenshots

        // Apply today's filter if enabled
        if showTodayOnly {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            filtered = filtered.filter { screenshot in
                calendar.isDate(screenshot.creationDate, inSameDayAs: today)
            }
        }

        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { screenshot in
                screenshot.fileName.localizedCaseInsensitiveContains(searchText) ||
                screenshot.title?.localizedCaseInsensitiveContains(searchText) == true
            }
        }

        return filtered.count
    }

    // MARK: - Sync

    /// Sync screenshots from photo library
    /// - Parameter modelContext: SwiftData model context
    func syncScreenshots(modelContext: ModelContext) async {
        await photoLibraryService.syncScreenshots(modelContext: modelContext)
    }

    // MARK: - Deletion

    /// Delete a single screenshot from the app
    /// - Parameters:
    ///   - screenshot: Screenshot to delete
    ///   - modelContext: SwiftData model context
    func deleteScreenshot(_ screenshot: Screenshot, modelContext: ModelContext) {
        photoLibraryService.deleteFromApp(screenshots: [screenshot], modelContext: modelContext)
    }

    /// Delete multiple screenshots from the app
    /// - Parameters:
    ///   - screenshots: Array of screenshots to delete
    ///   - modelContext: SwiftData model context
    func deleteScreenshots(_ screenshots: [Screenshot], modelContext: ModelContext) {
        photoLibraryService.deleteFromApp(screenshots: screenshots, modelContext: modelContext)
    }
}
