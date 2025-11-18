//
//  ScreenshotDetailView.swift
//  ScreenFlow
//
//  Full-screen detail view for displaying screenshot with swipe navigation
//

import SwiftUI
import SwiftData

/// Full-screen view for displaying a screenshot with swipe navigation
struct ScreenshotDetailView: View {
    // MARK: - Properties

    /// Initial screenshot to display
    let screenshot: Screenshot

    /// All screenshots for swipe navigation
    @State private var allScreenshots: [Screenshot]

    /// Photo library service
    private let photoLibraryService = PhotoLibraryService.shared

    /// Environment dismiss action
    @Environment(\.dismiss) private var dismiss

    /// SwiftData model context
    @Environment(\.modelContext) private var modelContext

    /// Current index
    @State private var currentIndex: Int

    /// Scroll position tracking
    @State private var scrollPosition: Int?

    /// Show info sheet
    @State private var showInfoSheet = false

    /// Alert state
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    /// Track current sheet detent
    @State private var sheetDetent: PresentationDetent = .height(155)

    /// Deletion state
    @State private var isDeletingScreenshot = false

    // MARK: - Initialization

    init(screenshot: Screenshot, allScreenshots: [Screenshot]) {
        self.screenshot = screenshot
        _allScreenshots = State(initialValue: allScreenshots)

        // Find the initial index
        if let index = allScreenshots.firstIndex(where: { $0.id == screenshot.id }) {
            _currentIndex = State(initialValue: index)
        } else {
            _currentIndex = State(initialValue: 0)
        }
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 0) {
                        ForEach(Array(allScreenshots.enumerated()), id: \.element.id) { index, screenshot in
                                ScreenshotImageView(
                                    screenshot: screenshot,
                                    onAssetUnavailable: { handleMissingScreenshot(screenshot) }
                                )
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                                    .background(Color.black)
                                    .id(index)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .scrollPosition(id: $scrollPosition)
                .onAppear {
                    scrollPosition = currentIndex
                    proxy.scrollTo(currentIndex, anchor: .leading)

                    // Show info sheet immediately and keep it visible
                    showInfoSheet = true
                }
                .onChange(of: scrollPosition) { oldValue, newValue in
                    if let newValue = newValue, newValue != currentIndex {
                        currentIndex = newValue
                    }
                }
            }
        }
        .ignoresSafeArea()
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .disableSwipeBack()
        .onDisappear {
            // Dismiss the info sheet when navigating away
            showInfoSheet = false
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    // Dismiss info sheet before navigating back
                    showInfoSheet = false
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button(action: shareScreenshot) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .sheet(isPresented: $showInfoSheet) {
            ScreenshotInfoSheet(
                allScreenshots: allScreenshots,
                currentIndex: $currentIndex,
                currentDetent: $sheetDetent,
                isDeleting: isDeletingScreenshot,
                onDelete: deleteScreenshot
            )
            .presentationDetents([.height(155), .large], selection: $sheetDetent)
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled(true)
            .presentationBackgroundInteraction(.enabled)
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - Share Methods

    /// Share screenshot (placeholder - action to be added later)
    private func shareScreenshot() {
        // TODO: Implement share functionality
        let currentScreenshot = allScreenshots[safe: currentIndex]
        print("Share button tapped for screenshot: \(currentScreenshot?.fileName ?? "unknown")")
    }

    // MARK: - Deletion

    /// Delete the provided screenshot and advance to the next available one
    private func deleteScreenshot(_ screenshot: Screenshot) {
        guard !isDeletingScreenshot else { return }
        guard allScreenshots.contains(where: { $0.id == screenshot.id }) else { return }

        isDeletingScreenshot = true

        Task {
            do {
                try await photoLibraryService.deleteFromLibrary(
                    screenshot,
                    modelContext: modelContext
                )

                await MainActor.run {
                    removeScreenshotFromList(screenshot)
                    isDeletingScreenshot = false
                }
            } catch {
                await MainActor.run {
                    isDeletingScreenshot = false
                    showAlert(
                        title: "Unable to Delete",
                        message: (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                    )
                }
            }
        }
    }

    /// Remove a screenshot that is no longer available (e.g., deleted externally)
    @MainActor
    private func handleMissingScreenshot(_ screenshot: Screenshot) {
        removeScreenshotFromList(screenshot)
    }

    /// Remove screenshot from in-memory list and update navigation state
    @MainActor
    private func removeScreenshotFromList(_ screenshot: Screenshot) {
        guard let removedIndex = allScreenshots.firstIndex(where: { $0.id == screenshot.id }) else { return }

        allScreenshots.remove(at: removedIndex)

        if allScreenshots.isEmpty {
            showInfoSheet = false
            dismiss()
        } else {
            let newIndex = min(removedIndex, allScreenshots.count - 1)
            currentIndex = newIndex
            scrollPosition = newIndex
        }
    }

    // MARK: - Helper Methods

    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
}
