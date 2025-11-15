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

    /// Photo library service
    private let photoLibraryService = PhotoLibraryService.shared

    /// Re-analysis task for cancellation
    @State private var reanalysisTask: Task<Void, Never>?

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
                    scheduleReanalysis()

                    // Show info sheet immediately and keep it visible
                    showInfoSheet = true
                }
                .onChange(of: scrollPosition) { oldValue, newValue in
                    if let newValue = newValue, newValue != currentIndex {
                        currentIndex = newValue

                        // Re-analyze when swiping to a different screenshot with debouncing
                        scheduleReanalysis()
                    }
                }
            }
        }
        .ignoresSafeArea()
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            // Cancel any ongoing re-analysis when leaving the view
            reanalysisTask?.cancel()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button(action: shareScreenshot) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }

//            ToolbarItem(placement: .bottomBar) {
//                Menu {
//                    if let currentScreenshot = allScreenshots[safe: currentIndex] {
//                        // All actions
//                        if canSaveContact(currentScreenshot) {
//                            Button {
//                                performSaveContact(currentScreenshot)
//                            } label: {
//                                Label("Save Contact", systemImage: "person.crop.circle.badge.plus")
//                            }
//                        }
//
//                        Button {
//                            performCreateNote(currentScreenshot)
//                        } label: {
//                            Label("Create Note", systemImage: "note.text.badge.plus")
//                        }
//
//                        if canAddToCalendar(currentScreenshot) {
//                            Button {
//                                performAddToCalendar(currentScreenshot)
//                            } label: {
//                                Label("Add to Calendar", systemImage: "calendar.badge.plus")
//                            }
//                        }
//
//                        if canSaveBookmark(currentScreenshot) {
//                            Button {
//                                performSaveBookmark(currentScreenshot)
//                            } label: {
//                                Label("Save Bookmark", systemImage: "bookmark.fill")
//                            }
//                        }
//
//                        if canOpenURL(currentScreenshot) {
//                            Button {
//                                performOpenURL(currentScreenshot)
//                            } label: {
//                                Label("Open Link", systemImage: "link")
//                            }
//                        }
//
//                        if canOpenMap(currentScreenshot) {
//                            Button {
//                                performOpenMap(currentScreenshot)
//                            } label: {
//                                Label("Open in Maps", systemImage: "map.fill")
//                            }
//                        }
//
//                        if canMakeCall(currentScreenshot) {
//                            Button {
//                                performMakeCall(currentScreenshot)
//                            } label: {
//                                Label("Make Call", systemImage: "phone.fill")
//                            }
//                        }
//
//                        if canSendEmail(currentScreenshot) {
//                            Button {
//                                performSendEmail(currentScreenshot)
//                            } label: {
//                                Label("Send Email", systemImage: "envelope.fill")
//                            }
//                        }
//
//                        if canCopyText(currentScreenshot) {
//                            Button {
//                                performCopyText(currentScreenshot)
//                            } label: {
//                                Label("Copy Text", systemImage: "doc.on.doc")
//                            }
//                        }
//
//                        Button {
//                            performSaveToPhotos(currentScreenshot)
//                        } label: {
//                            Label("Save to Photos", systemImage: "photo.on.rectangle.angled")
//                        }
//
//                        Button {
//                            performShareImage(currentScreenshot)
//                        } label: {
//                            Label("Share", systemImage: "square.and.arrow.up")
//                        }
//                    }
//                } label: {
//                    Label("Actions", systemImage: "wand.and.stars")
//                        .font(.headline)
//                }
//                .menuStyle(.button)
//            }
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

    // MARK: - Methods

    /// Schedule re-analysis with debouncing to prevent UI freeze
    private func scheduleReanalysis() {
        // Cancel any existing analysis task
        reanalysisTask?.cancel()

        // Schedule new analysis with background priority to never interfere with UI
        reanalysisTask = Task(priority: .background) {
            // Wait 1.5 seconds to ensure scroll animation has completed
            try? await Task.sleep(nanoseconds: 1_500_000_000)

            // Check if task was cancelled during the delay
            guard !Task.isCancelled else { return }

            // Get the current screenshot
            guard let currentScreenshot = allScreenshots[safe: currentIndex] else { return }

            // Perform re-analysis in background
            await photoLibraryService.reanalyzeScreenshot(
                for: currentScreenshot,
                modelContext: modelContext
            )
        }
    }

    /// Share screenshot (placeholder - action to be added later)
    private func shareScreenshot() {
        // TODO: Implement share functionality
        let currentScreenshot = allScreenshots[safe: currentIndex]
        print("Share button tapped for screenshot: \(currentScreenshot?.fileName ?? "unknown")")
    }

    // MARK: - Action Validation Helpers

    private func canSaveContact(_ screenshot: Screenshot) -> Bool {
        guard let extracted = screenshot.extractedData else { return false }
        return extracted.contactName != nil ||
               !extracted.emails.isEmpty ||
               !extracted.phoneNumbers.isEmpty
    }

    private func canAddToCalendar(_ screenshot: Screenshot) -> Bool {
        guard let extracted = screenshot.extractedData else { return false }
        return extracted.eventName != nil || extracted.eventDate != nil
    }

    private func canSaveBookmark(_ screenshot: Screenshot) -> Bool {
        guard let extracted = screenshot.extractedData else { return false }
        return !extracted.urls.isEmpty
    }

    private func canOpenURL(_ screenshot: Screenshot) -> Bool {
        guard let extracted = screenshot.extractedData else { return false }
        return !extracted.urls.isEmpty
    }

    private func canOpenMap(_ screenshot: Screenshot) -> Bool {
        guard let extracted = screenshot.extractedData else { return false }
        return !extracted.addresses.isEmpty || extracted.eventLocation != nil
    }

    private func canMakeCall(_ screenshot: Screenshot) -> Bool {
        guard let extracted = screenshot.extractedData else { return false }
        return !extracted.phoneNumbers.isEmpty || extracted.contactPhone != nil
    }

    private func canSendEmail(_ screenshot: Screenshot) -> Bool {
        guard let extracted = screenshot.extractedData else { return false }
        return !extracted.emails.isEmpty || extracted.contactEmail != nil
    }

    private func canCopyText(_ screenshot: Screenshot) -> Bool {
        guard let extracted = screenshot.extractedData else { return false }
        return extracted.fullText != nil && !(extracted.fullText?.isEmpty ?? true)
    }

    // MARK: - Action Execution Methods

    private func performSaveContact(_ screenshot: Screenshot) {
        guard let extracted = screenshot.extractedData else {
            showAlert(title: "Cannot Save Contact", message: "No contact information found")
            return
        }

        let contact = CNMutableContact()

        // Add name
        if let name = extracted.contactName {
            let components = name.components(separatedBy: " ")
            if components.count > 0 {
                contact.givenName = components[0]
            }
            if components.count > 1 {
                contact.familyName = components.dropFirst().joined(separator: " ")
            }
        }

        // Add phone numbers
        for phoneNumber in extracted.phoneNumbers {
            contact.phoneNumbers.append(CNLabeledValue(
                label: CNLabelPhoneNumberMain,
                value: CNPhoneNumber(stringValue: phoneNumber)
            ))
        }
        if let contactPhone = extracted.contactPhone {
            contact.phoneNumbers.append(CNLabeledValue(
                label: CNLabelPhoneNumberMain,
                value: CNPhoneNumber(stringValue: contactPhone)
            ))
        }

        // Add emails
        for email in extracted.emails {
            contact.emailAddresses.append(CNLabeledValue(
                label: CNLabelHome,
                value: email as NSString
            ))
        }
        if let contactEmail = extracted.contactEmail {
            contact.emailAddresses.append(CNLabeledValue(
                label: CNLabelWork,
                value: contactEmail as NSString
            ))
        }

        // Add company and job title
        if let company = extracted.contactCompany {
            contact.organizationName = company
        }
        if let jobTitle = extracted.contactJobTitle {
            contact.jobTitle = jobTitle
        }

        // Add address
        if let address = extracted.contactAddress {
            let postalAddress = CNMutablePostalAddress()
            postalAddress.street = address
            contact.postalAddresses.append(CNLabeledValue(
                label: CNLabelWork,
                value: postalAddress
            ))
        }

        contactToSave = contact
        showingContactView = true
    }

    private func performCreateNote(_ screenshot: Screenshot) {
        guard let extracted = screenshot.extractedData else {
            showAlert(title: "No Data Available", message: "This screenshot hasn't been analyzed yet.")
            return
        }

        guard let fullText = extracted.fullText?.trimmingCharacters(in: .whitespacesAndNewlines),
              !fullText.isEmpty else {
            showAlert(title: "No Text Found", message: "No text detected on this screenshot.")
            return
        }

        guard fullText.count >= 20 else {
            showAlert(title: "Needs More Text", message: "At least 20 characters are required to create a note.")
            return
        }

        presentShareSheet(with: fullText)
    }

    private func presentShareSheet(with text: String) {
        let activityVC = UIActivityViewController(
            activityItems: [NoteTextActivityItemSource(text: text)],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {

            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootVC.view
                popover.sourceRect = CGRect(
                    x: rootVC.view.bounds.midX,
                    y: rootVC.view.bounds.midY,
                    width: 0,
                    height: 0
                )
                popover.permittedArrowDirections = []
            }

            var topController = rootVC
            while let presented = topController.presentedViewController {
                topController = presented
            }

            topController.present(activityVC, animated: true)
        } else {
            showAlert(title: "Cannot Share", message: "Unable to present share sheet")
        }
    }

    private func performAddToCalendar(_ screenshot: Screenshot) {
        guard let extracted = screenshot.extractedData else {
            showAlert(title: "No Data Available", message: "This screenshot hasn't been analyzed yet")
            return
        }

        guard extracted.eventName != nil || extracted.eventDate != nil else {
            showAlert(title: "No Event Information", message: "No event details found on this screenshot")
            return
        }

        let eventStore = EKEventStore()
        Task {
            do {
                let granted = try await eventStore.requestFullAccessToEvents()
                if granted {
                    let event = EKEvent(eventStore: eventStore)
                    event.title = extracted.eventName ?? "Event from Screenshot"
                    event.startDate = extracted.eventDate ?? Date()
                    event.endDate = extracted.eventEndDate ?? event.startDate.addingTimeInterval(3600)
                    event.location = extracted.eventLocation
                    event.notes = extracted.eventDescription
                    event.calendar = eventStore.defaultCalendarForNewEvents

                    try eventStore.save(event, span: .thisEvent)

                    await MainActor.run {
                        showAlert(title: "Event Created", message: "Event added to calendar successfully")
                    }
                } else {
                    await MainActor.run {
                        showAlert(title: "Permission Denied", message: "Calendar access is required")
                    }
                }
            } catch {
                await MainActor.run {
                    showAlert(title: "Error", message: "Failed to create event: \(error.localizedDescription)")
                }
            }
        }
    }

    private func performSaveBookmark(_ screenshot: Screenshot) {
        guard let extracted = screenshot.extractedData else {
            showAlert(title: "No Data Available", message: "This screenshot hasn't been analyzed yet")
            return
        }

        let validURLs = normalizedURLs(from: extracted)

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
            await addBookmarksToReadingList(urlsToSave)
        }
    }

    private func addBookmarksToReadingList(_ urls: [URL]) async {
        print("📚 Attempting to save \(urls.count) bookmark(s) to Reading List:")
        for (index, url) in urls.enumerated() {
            print("  \(index + 1). \(url.absoluteString)")
        }

        guard let readingList = SSReadingList.default() else {
            await MainActor.run {
                showAlert(title: "Reading List Unavailable", message: "Safari Reading List cannot be accessed right now")
            }
            return
        }

        var savedCount = 0
        var failureMessages: [String] = []

        for (index, url) in urls.enumerated() {
            // Safari Reading List requires main thread access
            await MainActor.run {
                do {
                    try readingList.addItem(with: url, title: url.host, previewText: nil)
                    savedCount += 1
                    print("✅ Saved bookmark \(index + 1)/\(urls.count): \(url.absoluteString)")
                } catch {
                    let nsError = error as NSError
                    let reason: String
                    if nsError.domain == SSReadingListErrorDomain,
                       let code = SSReadingListError.Code(rawValue: nsError.code) {
                        switch code {
                        case .urlSchemeNotAllowed:
                            reason = "URL scheme not allowed"
                        default:
                            reason = nsError.localizedDescription
                        }
                    } else {
                        reason = nsError.localizedDescription
                    }
                    let shortURL = url.host ?? url.absoluteString
                    failureMessages.append("• \(shortURL): \(reason)")
                    print("❌ Failed to save bookmark \(index + 1)/\(urls.count): \(url.absoluteString) - \(reason)")
                }
            }

            // Safari Reading List needs significant delay between insertions to process them reliably
            // 150ms is too fast and causes Safari to silently drop URLs
            if index < urls.count - 1 {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
            }
        }

        await MainActor.run {
            if savedCount == urls.count {
                let message = savedCount == 1
                    ? "URL added to Safari Reading List"
                    : "\(savedCount) URLs added to Safari Reading List"
                showAlert(title: "Bookmarks Saved", message: message)
            } else if savedCount > 0 {
                let details = failureMessages.joined(separator: "\n")
                showAlert(
                    title: "Partially Saved",
                    message: "Saved \(savedCount) of \(urls.count) link(s).\n\nFailed:\n\(details)"
                )
            } else {
                let details = failureMessages.isEmpty ? "Unknown error" : failureMessages.joined(separator: "\n")
                showAlert(title: "Unable to Save", message: "Could not add to Reading List:\n\(details)")
            }
        }
    }

    private func normalizedURLs(from data: ExtractedData) -> [URL] {
        var seen = Set<URL>()
        var results: [URL] = []

        for rawValue in data.urls {
            guard let normalized = normalizedURL(from: rawValue) else { continue }

            if seen.insert(normalized).inserted {
                results.append(normalized)
            }
        }

        return results
    }

    private func normalizedURL(from rawValue: String) -> URL? {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        var candidate = trimmed
        let lowercased = candidate.lowercased()
        if !lowercased.hasPrefix("http://") && !lowercased.hasPrefix("https://") {
            candidate = "https://\(candidate)"
        }

        guard let url = URL(string: candidate),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else {
            return nil
        }

        return url
    }

    private func performOpenURL(_ screenshot: Screenshot) {
        guard let extracted = screenshot.extractedData else {
            showAlert(title: "No Data Available", message: "This screenshot hasn't been analyzed yet")
            return
        }

        guard let firstURL = extracted.urls.first else {
            showAlert(title: "No URL Found", message: "No website link found on this screenshot")
            return
        }

        guard let url = URL(string: firstURL) else {
            showAlert(title: "Invalid URL", message: "The URL format is invalid")
            return
        }

        UIApplication.shared.open(url)
    }

    private func performOpenMap(_ screenshot: Screenshot) {
        guard let extracted = screenshot.extractedData else {
            showAlert(title: "No Data Available", message: "This screenshot hasn't been analyzed yet")
            return
        }

        let address = extracted.addresses.first ?? extracted.eventLocation ?? ""

        guard !address.isEmpty else {
            showAlert(title: "No Address Found", message: "No location or address found on this screenshot")
            return
        }

        if let encoded = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: "http://maps.apple.com/?q=\(encoded)") {
            UIApplication.shared.open(url)
        } else {
            showAlert(title: "Invalid Address", message: "Could not process the address")
        }
    }

    private func performMakeCall(_ screenshot: Screenshot) {
        guard let extracted = screenshot.extractedData else {
            showAlert(title: "No Data Available", message: "This screenshot hasn't been analyzed yet")
            return
        }

        let phoneNumber = extracted.phoneNumbers.first ?? extracted.contactPhone ?? ""

        guard !phoneNumber.isEmpty else {
            showAlert(title: "No Phone Number", message: "No phone number found on this screenshot")
            return
        }

        let cleaned = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()

        guard !cleaned.isEmpty else {
            showAlert(title: "Invalid Phone Number", message: "The phone number format is invalid")
            return
        }

        if let url = URL(string: "tel://\(cleaned)") {
            UIApplication.shared.open(url)
        } else {
            showAlert(title: "Cannot Make Call", message: "Unable to initiate phone call")
        }
    }

    private func performSendEmail(_ screenshot: Screenshot) {
        guard let extracted = screenshot.extractedData else {
            showAlert(title: "No Data Available", message: "This screenshot hasn't been analyzed yet")
            return
        }

        let email = extracted.emails.first ?? extracted.contactEmail ?? ""

        guard !email.isEmpty else {
            showAlert(title: "No Email Address", message: "No email address found on this screenshot")
            return
        }

        if let url = URL(string: "mailto:\(email)") {
            UIApplication.shared.open(url)
        } else {
            showAlert(title: "Invalid Email", message: "The email address format is invalid")
        }
    }

    private func performCopyText(_ screenshot: Screenshot) {
        guard let extracted = screenshot.extractedData else {
            showAlert(title: "No Data Available", message: "This screenshot hasn't been analyzed yet")
            return
        }

        guard let text = extracted.fullText, !text.isEmpty else {
            showAlert(title: "No Text Found", message: "No text detected on this screenshot")
            return
        }

        UIPasteboard.general.string = text
        showAlert(title: "Text Copied", message: "Text copied to clipboard successfully")
    }

    private func performSaveToPhotos(_ screenshot: Screenshot) {
        PhotoLibraryService.shared.fetchFullImage(for: screenshot) { image in
            guard let image = image else {
                DispatchQueue.main.async {
                    self.showAlert(title: "Cannot Save", message: "Failed to load screenshot image")
                }
                return
            }

            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                guard status == .authorized else {
                    DispatchQueue.main.async {
                        self.showAlert(title: "Permission Denied", message: "Photos access is required to save images")
                    }
                    return
                }

                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                }) { success, error in
                    DispatchQueue.main.async {
                        if success {
                            self.showAlert(title: "Saved to Photos", message: "Screenshot saved to your Photos library")
                        } else if let error = error {
                            self.showAlert(title: "Save Failed", message: "Could not save: \(error.localizedDescription)")
                        } else {
                            self.showAlert(title: "Save Failed", message: "An unknown error occurred")
                        }
                    }
                }
            }
        }
    }

    private func performShareImage(_ screenshot: Screenshot) {
        PhotoLibraryService.shared.fetchFullImage(for: screenshot) { image in
            guard let image = image else {
                DispatchQueue.main.async {
                    self.showAlert(title: "Cannot Share", message: "Failed to load screenshot image")
                }
                return
            }

            DispatchQueue.main.async {
                let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let rootVC = window.rootViewController {
                    rootVC.present(activityVC, animated: true)
                } else {
                    self.showAlert(title: "Cannot Share", message: "Unable to present share sheet")
                }
            }
        }
    }

    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
}

// MARK: - Contact View Controller

/// SwiftUI wrapper for CNContactViewController
struct ContactViewController: UIViewControllerRepresentable {
    let contact: CNMutableContact
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> UINavigationController {
        let contactVC = CNContactViewController(forNewContact: contact)
        contactVC.delegate = context.coordinator
        contactVC.contactStore = CNContactStore()

        let navController = UINavigationController(rootViewController: contactVC)
        return navController
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss)
    }

    class Coordinator: NSObject, CNContactViewControllerDelegate {
        let onDismiss: () -> Void

        init(onDismiss: @escaping () -> Void) {
            self.onDismiss = onDismiss
        }

        func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
            onDismiss()
        }
    }
}

// MARK: - Bookmark Selection Sheet

struct BookmarkSelectionSheet: View {
    let links: [BookmarkLink]
    @Binding var selectedIDs: Set<BookmarkLink.ID>
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            List {
                if links.isEmpty {
                    Text("No links detected")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    ForEach(links) { link in
                        Toggle(isOn: binding(for: link)) {
                            Text(link.url.absoluteString)
                                .font(.body)
                                .textSelection(.enabled)
                                .lineLimit(2)
                        }
                    }
                }
            }
            .navigationTitle("Select Links")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                    }
                    .disabled(selectedIDs.isEmpty)
                }
            }
        }
    }

    private func binding(for link: BookmarkLink) -> Binding<Bool> {
        Binding(
            get: { selectedIDs.contains(link.id) },
            set: { isSelected in
                if isSelected {
                    selectedIDs.insert(link.id)
                } else {
                    selectedIDs.remove(link.id)
                }
            }
        )
    }
}

struct BookmarkLink: Identifiable, Hashable {
    let id = UUID()
    let url: URL
}
