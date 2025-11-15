//
//  ScreenshotDetailView.swift
//  ScreenFlow
//
//  Full-screen detail view for displaying screenshot with swipe navigation
//

import SwiftUI
import SwiftData
import Contacts
import ContactsUI
import EventKit
import Photos
import SafariServices

/// Full-screen view for displaying a screenshot with swipe navigation
struct ScreenshotDetailView: View {
    // MARK: - Properties

    /// Initial screenshot to display
    let screenshot: Screenshot

    /// All screenshots for swipe navigation
    let allScreenshots: [Screenshot]

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

    /// Show universal actions sheet
    @State private var showActionsSheet = false

    /// Screenshot selected for action
    @State private var selectedScreenshotForAction: Screenshot?

    /// Alert state
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    /// Contact to save
    @State private var contactToSave: CNMutableContact?
    @State private var showingContactView = false

    /// Bookmark selection state
    @State private var showBookmarkSelection = false
    @State private var bookmarkOptions: [BookmarkLink] = []
    @State private var selectedBookmarkIDs: Set<BookmarkLink.ID> = []

    /// Re-analysis scheduler
    @State private var reanalysisScheduler = ReanalysisScheduler()

    // MARK: - Initialization

    init(screenshot: Screenshot, allScreenshots: [Screenshot]) {
        self.screenshot = screenshot
        self.allScreenshots = allScreenshots

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
                                ScreenshotImageView(screenshot: screenshot)
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

                    // Re-analyze the initial screenshot with debouncing
                    if let currentScreenshot = allScreenshots[safe: currentIndex] {
                        reanalysisScheduler.scheduleReanalysis(
                            for: currentScreenshot,
                            modelContext: modelContext
                        )
                    }

                    // Show info sheet immediately and keep it visible
                    showInfoSheet = true
                }
                .onChange(of: scrollPosition) { oldValue, newValue in
                    if let newValue = newValue, newValue != currentIndex {
                        currentIndex = newValue

                        // Re-analyze when swiping to a different screenshot with debouncing
                        if let currentScreenshot = allScreenshots[safe: currentIndex] {
                            reanalysisScheduler.scheduleReanalysis(
                                for: currentScreenshot,
                                modelContext: modelContext
                            )
                        }
                    }
                }
            }
        }
        .ignoresSafeArea()
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            // Cancel any ongoing re-analysis when leaving the view
            reanalysisScheduler.cancelReanalysis()
        }
        .toolbar {
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
                currentIndex: $currentIndex
            )
            .presentationDetents([.height(155), .large])
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled(true)
            .presentationBackgroundInteraction(.enabled)
        }
        .sheet(isPresented: $showActionsSheet) {
            if let screenshot = selectedScreenshotForAction {
                UniversalActionSheet(screenshot: screenshot)
            }
        }
        .sheet(isPresented: $showingContactView) {
            if let contact = contactToSave {
                ContactViewController(contact: contact) {
                    showingContactView = false
                }
            }
        }
        .sheet(isPresented: $showBookmarkSelection) {
            BookmarkSelectionSheet(
                links: bookmarkOptions,
                selectedIDs: $selectedBookmarkIDs,
                onCancel: { showBookmarkSelection = false },
                onSave: { saveSelectedBookmarks() }
            )
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

    // MARK: - Action Execution Methods

    private func performSaveContact(_ screenshot: Screenshot) {
        switch ContactActionHelper.prepareContact(from: screenshot) {
        case .success(let contact):
            contactToSave = contact
            showingContactView = true
        case .failure(let title, let message):
            showAlert(title: title, message: message)
        }
    }

    private func performCreateNote(_ screenshot: Screenshot) {
        switch TextActionHelper.createNote(from: screenshot) {
        case .success(let title, let message):
            showAlert(title: title, message: message)
        case .failure(let title, let message):
            showAlert(title: title, message: message)
        case .presentShareSheet(let text):
            if !TextActionHelper.presentShareSheet(with: text) {
                showAlert(title: "Cannot Share", message: "Unable to present share sheet")
            }
        }
    }

    private func performAddToCalendar(_ screenshot: Screenshot) {
        guard let currentScreenshot = allScreenshots[safe: currentIndex] else { return }

        Task {
            let result = await CalendarActionHelper.addToCalendar(from: currentScreenshot)
            await MainActor.run {
                switch result {
                case .success(let title, let message):
                    showAlert(title: title, message: message)
                case .failure(let title, let message):
                    showAlert(title: title, message: message)
                }
            }
        }
    }

    private func performSaveBookmark(_ screenshot: Screenshot) {
        guard let extracted = screenshot.extractedData else {
            showAlert(title: "No Data Available", message: "This screenshot hasn't been analyzed yet")
            return
        }

        let validURLs = URLNormalizer.normalizedURLs(from: extracted)

        guard !validURLs.isEmpty else {
            showAlert(title: "No URL Found", message: "No website link found on this screenshot")
            return
        }

        bookmarkOptions = validURLs.map { BookmarkLink(url: $0) }
        selectedBookmarkIDs = Set(bookmarkOptions.map(\.id))
        showBookmarkSelection = true
    }

    private func saveSelectedBookmarks() {
        let urlsToSave = bookmarkOptions
            .filter { selectedBookmarkIDs.contains($0.id) }
            .map(\.url)

        print("🔖 Selected \(selectedBookmarkIDs.count) bookmark(s) from \(bookmarkOptions.count) total")
        print("🔖 URLs to save: \(urlsToSave.count)")

        guard !urlsToSave.isEmpty else {
            showBookmarkSelection = false
            showAlert(title: "No URL Selected", message: "Select at least one link to save")
            return
        }

        showBookmarkSelection = false

        Task {
            if let result = await BookmarkActionHelper.addBookmarksToReadingList(urlsToSave) {
                await MainActor.run {
                    showAlert(title: result.title, message: result.message)
                }
            } else {
                await MainActor.run {
                    showAlert(title: "Reading List Unavailable", message: "Safari Reading List cannot be accessed right now")
                }
            }
        }
    }

    private func performOpenURL(_ screenshot: Screenshot) {
        switch URLActionHelper.openURL(from: screenshot) {
        case .success:
            break
        case .failure(let title, let message):
            showAlert(title: title, message: message)
        }
    }

    private func performOpenMap(_ screenshot: Screenshot) {
        switch MapActionHelper.openMap(from: screenshot) {
        case .success:
            break
        case .failure(let title, let message):
            showAlert(title: title, message: message)
        }
    }

    private func performMakeCall(_ screenshot: Screenshot) {
        switch CommunicationActionHelper.makeCall(from: screenshot) {
        case .success:
            break
        case .failure(let title, let message):
            showAlert(title: title, message: message)
        }
    }

    private func performSendEmail(_ screenshot: Screenshot) {
        switch CommunicationActionHelper.sendEmail(from: screenshot) {
        case .success:
            break
        case .failure(let title, let message):
            showAlert(title: title, message: message)
        }
    }

    private func performCopyText(_ screenshot: Screenshot) {
        switch TextActionHelper.copyText(from: screenshot) {
        case .success(let title, let message):
            showAlert(title: title, message: message)
        case .failure(let title, let message):
            showAlert(title: title, message: message)
        case .presentShareSheet:
            break // Not applicable for copy
        }
    }

    private func performSaveToPhotos(_ screenshot: Screenshot) {
        PhotoActionHelper.saveToPhotos(screenshot: screenshot) { result in
            switch result {
            case .success(let title, let message):
                showAlert(title: title, message: message)
            case .failure(let title, let message):
                showAlert(title: title, message: message)
            }
        }
    }

    private func performShareImage(_ screenshot: Screenshot) {
        PhotoActionHelper.shareImage(screenshot: screenshot) { image in
            guard let image = image else {
                showAlert(title: "Cannot Share", message: "Failed to load screenshot image")
                return
            }

            if !PhotoActionHelper.presentShareSheet(with: image) {
                showAlert(title: "Cannot Share", message: "Unable to present share sheet")
            }
        }
    }

    // MARK: - Helper Methods

    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
}
