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

    /// Edit mode state
    @State private var editMode: EditMode = .inactive

    /// Selected screenshots for bulk operations
    @State private var selectedScreenshots = Set<Screenshot.ID>()

    /// Search text
    @State private var searchText = ""

    /// Refresh trigger
    @State private var isRefreshing = false

    /// Loading state for first launch
    @State private var isLoading = true

    /// Permission denied alert
    @State private var showPermissionAlert = false

    /// Number of items to display (for pagination)
    @State private var displayLimit = 20

    /// Filter option: today or all
    @State private var showTodayOnly = true

    /// Background title generation task
    @State private var titleGenerationTask: Task<Void, Never>?

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
                    ScreenshotListContentView(
                        screenshots: filteredScreenshots,
                        allScreenshots: allFilteredScreenshots,
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
            .searchable(text: $searchText, placement: .toolbarPrincipal, prompt: "Search")
            .environment(\.editMode, $editMode)
            .task {
                await requestPermissionAndSync()
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
                // Reset pagination when filter changes
                displayLimit = 20
            }
            .onChange(of: searchText) { oldValue, newValue in
                // Reset pagination when search changes
                displayLimit = 20
            }
            .onDisappear {
                // Cancel background task when view disappears
                titleGenerationTask?.cancel()
            }
            .alert("Photo Library Access Required", isPresented: $showPermissionAlert) {
                Button("Settings", action: openSettings)
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Please grant access to your photo library in Settings to use this app.")
            }
        }
    }

    // MARK: - Computed Properties

    /// Filtered screenshots based on search text, date filter, and pagination
    private var filteredScreenshots: [Screenshot] {
        screenshotService.filterScreenshots(
            allScreenshots,
            searchText: searchText,
            showTodayOnly: showTodayOnly,
            limit: displayLimit
        )
    }

    /// All filtered screenshots without pagination (for navigation)
    private var allFilteredScreenshots: [Screenshot] {
        screenshotService.filterScreenshots(
            allScreenshots,
            searchText: searchText,
            showTodayOnly: showTodayOnly,
            limit: Int.max
        )
    }

    /// Get total count for subtitle (before pagination)
    private var totalFilteredCount: Int {
        screenshotService.getFilteredCount(
            allScreenshots,
            searchText: searchText,
            showTodayOnly: showTodayOnly
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

        // Start background title generation after initial sync completes
        if granted {
            startBackgroundTitleGeneration()
        }
    }

    /// Sync screenshots from photo library
    private func syncScreenshots() async {
        isRefreshing = true
        await screenshotService.syncScreenshots(modelContext: modelContext)
        isRefreshing = false

        // Start background title generation after sync completes
        startBackgroundTitleGeneration()
    }

    /// Delete a single screenshot from the app
    private func deleteScreenshot(_ screenshot: Screenshot) {
        withAnimation {
            screenshotService.deleteScreenshot(screenshot, modelContext: modelContext)
        }
    }

    /// Delete selected screenshots
    private func deleteSelectedScreenshots() {
        withAnimation {
            let screenshotsToDelete = allScreenshots.filter { selectedScreenshots.contains($0.id) }
            screenshotService.deleteScreenshots(screenshotsToDelete, modelContext: modelContext)
            selectedScreenshots.removeAll()
            editMode = .inactive
        }
    }

    /// Load more items (pagination)
    private func loadMoreItems() {
        displayLimit += 20
    }

    /// Open Settings app
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    /// Start background title generation for screenshots that don't have titles
    /// This is called ONLY after sync operations complete, not during scrolling
    private func startBackgroundTitleGeneration() {
        // Cancel any existing task
        titleGenerationTask?.cancel()

        // Start a new background task
        titleGenerationTask = Task {
            // Get ALL screenshots that need titles (not just filtered/paginated ones)
            let screenshotsNeedingTitles = allScreenshots.filter { $0.title == nil }

            // Process them one at a time with delays to avoid UI freeze
            for screenshot in screenshotsNeedingTitles {
                // Check if task was cancelled
                guard !Task.isCancelled else { return }

                // Generate title for this screenshot
                await photoLibraryService.generateTitleIfNeeded(
                    for: screenshot,
                    modelContext: modelContext
                )

                // Wait before processing next one to keep UI responsive
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds between each
            }
        }
    }
}
