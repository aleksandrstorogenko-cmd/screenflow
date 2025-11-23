//
//  FilteredScreenshotList.swift
//  ScreenFlow
//
//  A wrapper view that handles dynamic SwiftData queries for screenshots
//

import SwiftUI
import SwiftData

/// A view that handles the SwiftData query based on filter criteria
struct FilteredScreenshotList: View {
    /// The query result
    @Query private var screenshots: [Screenshot]
    
    /// Pagination view model
    @ObservedObject var paginationViewModel: ScreenshotPaginationViewModel
    
    /// Selected screenshots binding
    @Binding var selectedScreenshots: Set<Screenshot.ID>
    
    /// Callback for deletion
    let onDelete: (Screenshot) -> Void
    
    /// Callback for loading more items
    let onLoadMore: () -> Void

    /// Initialize with filter criteria
    /// - Parameters:
    ///   - showTodayOnly: Whether to filter for today's screenshots
    ///   - paginationViewModel: View model for pagination
    ///   - selectedScreenshots: Binding to selected screenshots
    ///   - onDelete: Deletion callback
    ///   - onLoadMore: Load more callback
    init(
        showTodayOnly: Bool,
        paginationViewModel: ScreenshotPaginationViewModel,
        selectedScreenshots: Binding<Set<Screenshot.ID>>,
        onDelete: @escaping (Screenshot) -> Void,
        onLoadMore: @escaping () -> Void
    ) {
        self.paginationViewModel = paginationViewModel
        self._selectedScreenshots = selectedScreenshots
        self.onDelete = onDelete
        self.onLoadMore = onLoadMore

        // Configure the query based on the filter
        if showTodayOnly {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            // Note: We use a static date here. If the day changes while the app is running,
            // this might need a refresh mechanism, but for "Today" filter it's usually acceptable.
            let predicate = #Predicate<Screenshot> { screenshot in
                screenshot.creationDate >= today
            }
            _screenshots = Query(filter: predicate, sort: \.creationDate, order: .reverse)
        } else {
            _screenshots = Query(sort: \.creationDate, order: .reverse)
        }
    }
    
    var body: some View {
        MasonryScreenshotListView(
            screenshots: paginationViewModel.visibleScreenshots,
            allScreenshots: screenshots,
            isLoadingMore: paginationViewModel.isLoadingPage,
            canLoadMore: paginationViewModel.canLoadMore,
            selectedScreenshots: $selectedScreenshots,
            onDelete: onDelete,
            onLoadMore: onLoadMore
        )
        .onAppear {
            // Initialize the view model with data
            paginationViewModel.updateSourceScreenshots(screenshots)
        }
        .onChange(of: screenshots) { _, newScreenshots in
            // Update view model when data changes
            paginationViewModel.updateSourceScreenshots(newScreenshots)
        }
    }
}
