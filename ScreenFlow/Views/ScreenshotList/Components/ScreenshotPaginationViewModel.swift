//
//  ScreenshotPaginationViewModel.swift
//  ScreenFlow
//
//  Handles lazy pagination for the screenshot list
//

import SwiftUI
import Combine

/// View model that exposes paginated batches of screenshots for infinite scrolling
@MainActor
final class ScreenshotPaginationViewModel: ObservableObject {
    /// Screenshots currently rendered by the UI
    @Published private(set) var visibleScreenshots: [Screenshot] = []

    /// Indicates whether another page request is running
    @Published private(set) var isLoadingPage = false

    /// Number of items per page
    private let pageSize: Int

    /// Full filtered dataset
    private var sourceScreenshots: [Screenshot] = []

    /// Track identifiers to detect data changes
    private var sourceIdentifiers: [String] = []

    /// Index where the next batch should start
    private var nextIndex: Int = 0

    init(pageSize: Int = 20) {
        self.pageSize = pageSize
    }

    /// Update the data source and optionally force a reset (used when filters change)
    func updateSourceScreenshots(_ newScreenshots: [Screenshot], forceReset: Bool = false) {
        let newIdentifiers = newScreenshots.map(\.assetIdentifier)
        let identifiersChanged = newIdentifiers != sourceIdentifiers

        sourceScreenshots = newScreenshots
        sourceIdentifiers = newIdentifiers

        if forceReset || visibleScreenshots.isEmpty {
            restartPagination()
            return
        }

        if identifiersChanged {
            // Handle deletions intelligently: maintain scroll position
            // Keep the same number of items visible, but update to the new data
            let currentlyVisibleCount = visibleScreenshots.count
            let newVisibleCount = min(currentlyVisibleCount, newScreenshots.count)
            
            visibleScreenshots = Array(newScreenshots.prefix(newVisibleCount))
            nextIndex = newVisibleCount
            return
        }

        // Clamp already loaded items in case the backing data shrank
        let loadedCount = min(visibleScreenshots.count, newScreenshots.count)
        visibleScreenshots = Array(newScreenshots.prefix(loadedCount))
        nextIndex = loadedCount
    }

    /// Request the next page if possible
    func loadNextPageIfNeeded() {
        guard !isLoadingPage else { return }
        guard nextIndex < sourceScreenshots.count else { return }

        isLoadingPage = true

        Task { @MainActor in
            // Slight delay keeps the loader visible and debounces rapid triggers
            try? await Task.sleep(nanoseconds: 200_000_000)
            appendNextPage()
            isLoadingPage = false
        }
    }

    /// Whether more pages are available
    var canLoadMore: Bool {
        nextIndex < sourceScreenshots.count
    }

    /// Append the next chunk to the visible array
    private func appendNextPage() {
        let endIndex = min(nextIndex + pageSize, sourceScreenshots.count)
        guard nextIndex < endIndex else { return }

        let newItems = sourceScreenshots[nextIndex..<endIndex]
        visibleScreenshots.append(contentsOf: newItems)
        nextIndex = endIndex
    }

    /// Reset pagination to the first page
    private func restartPagination() {
        visibleScreenshots = []
        nextIndex = 0
        isLoadingPage = false

        guard !sourceScreenshots.isEmpty else { return }
        loadNextPageIfNeeded()
    }
}
