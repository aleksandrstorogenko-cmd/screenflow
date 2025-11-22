//
//  ScreenshotListView.swift
//  ScreenFlow
//
//  Main view for displaying list of screenshots
//

import SwiftUI
import SwiftData

/// Main view displaying the list of all screenshots
struct ScreenshotListView: View {
    /// SwiftData model context
    @Environment(\.modelContext) private var modelContext

    /// Scene phase to track app lifecycle
    @Environment(\.scenePhase) private var scenePhase

    /// Fetch all screenshots from SwiftData, sorted by creation date
    @Query(sort: \Screenshot.creationDate, order: .reverse)
    private var allScreenshots: [Screenshot]

    /// Photo library service
    private let photoLibraryService = PhotoLibraryService.shared

    /// Screenshot service
    private let screenshotService = ScreenshotService.shared

    /// Pagination view model responsible for batching items
    @StateObject private var paginationViewModel = ScreenshotPaginationViewModel()

    /// Edit mode state
    @State private var editMode: EditMode = .inactive

    /// Selected screenshots for bulk operations
    @State private var selectedScreenshots = Set<Screenshot.ID>()

    /// Refresh trigger
    @State private var isRefreshing = false

    /// Loading state for first launch
    @State private var isLoading = true

    /// Permission denied alert
    @State private var showPermissionAlert = false

    /// Filter option: today or all
    @State private var showTodayOnly = false

    /// Background title generation task
    @State private var titleGenerationTask: Task<Void, Never>?

    /// Track whether pagination has been configured at least once
    @State private var hasInitializedPagination = false
    
    /// Deletion error state
    @State private var deletionError: Error?
    
    /// Show deletion error alert
    @State private var showDeletionErrorAlert = false

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    // Loading view on first launch
                    ProgressView("Syncing screenshots...")
                } else if !photoLibraryService.hasPermission() {
                    // Permission denied view
                    PermissionDeniedView(onGrantAccess: requestPermissionAndSync)
                } else {
                    // Main list view
                    MasonryScreenshotListView(
                        screenshots: paginationViewModel.visibleScreenshots,
                        allScreenshots: filteredScreenshots,
                        isLoadingMore: paginationViewModel.isLoadingPage,
                        canLoadMore: paginationViewModel.canLoadMore,
                        selectedScreenshots: $selectedScreenshots,
                        onDelete: deleteScreenshot,
                        onLoadMore: loadMoreItems
                    )
                }
            }
            .navigationTitle("Inbox")
            .navigationSubtitleIfAvailable("\(filteredScreenshots.count) screenshot(s)")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ScreenshotListToolbar(
                    editMode: $editMode,
                    showTodayOnly: $showTodayOnly,
                    selectedScreenshots: $selectedScreenshots,
                    onDeleteSelected: deleteSelectedScreenshots
                )
            }
            .environment(\.editMode, $editMode)
            .task {
                await requestPermissionAndSync()
            }
            .onAppear {
                guard !hasInitializedPagination else { return }
                paginationViewModel.updateSourceScreenshots(filteredScreenshots, forceReset: true)
                hasInitializedPagination = true
            }
            .refreshable {
                await syncScreenshots()
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                if newPhase == .active && oldPhase != .active {
                    // App became active - sync screenshots
                    Task {
                        await syncScreenshots()
                    }
                }
            }
            .onChange(of: showTodayOnly) { oldValue, newValue in
                paginationViewModel.updateSourceScreenshots(filteredScreenshots, forceReset: true)
            }
            .onChange(of: allScreenshots.map(\.assetIdentifier)) { _,_ in
                paginationViewModel.updateSourceScreenshots(filteredScreenshots)
            }
            .alert("Photo Library Access Required", isPresented: $showPermissionAlert) {
                Button("Settings", action: openSettings)
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Please grant access to your photo library in Settings to use this app.")
            }
            .alert("Deletion Failed", isPresented: $showDeletionErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                if let error = deletionError {
                    Text(error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Computed Properties

    /// Filtered screenshots based on search text and date filter
    private var filteredScreenshots: [Screenshot] {
        screenshotService.filterScreenshots(
            allScreenshots,
            showTodayOnly: showTodayOnly,
            limit: Int.max
        )
    }

    // MARK: - Methods

    /// Request permission and sync screenshots
    private func requestPermissionAndSync() async {
        let granted = await photoLibraryService.requestPermissionAndSync(modelContext: modelContext)

        if !granted {
            showPermissionAlert = true
        }

        isLoading = false
    }

    /// Sync screenshots from photo library
    private func syncScreenshots() async {
        isRefreshing = true
        await screenshotService.syncScreenshots(modelContext: modelContext)
        isRefreshing = false
    }

    /// Delete a single screenshot from the app
    private func deleteScreenshot(_ screenshot: Screenshot) {
        withAnimation {
            screenshotService.deleteScreenshot(screenshot, modelContext: modelContext)
        }
    }

    /// Delete selected screenshots
    private func deleteSelectedScreenshots() {
        Task {
            let screenshotsToDelete = allScreenshots.filter { selectedScreenshots.contains($0.id) }
            
            guard !screenshotsToDelete.isEmpty else { return }
            
            do {
                try await screenshotService.batchDeleteScreenshots(screenshotsToDelete, modelContext: modelContext)
                
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedScreenshots.removeAll()
                    }
                }
            } catch {
                await MainActor.run {
                    deletionError = error
                    showDeletionErrorAlert = true
                }
            }
        }
    }

    /// Load more items (pagination)
    private func loadMoreItems() {
        paginationViewModel.loadNextPageIfNeeded()
    }

    /// Open Settings app
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
