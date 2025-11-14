//
//  UniversalActionSheet.swift
//  ScreenFlow
//
//  Universal action selection sheet - user chooses action, app validates and executes
//

import SwiftUI
import Photos
import Contacts
import ContactsUI
import EventKit
import PhotosUI

/// Universal action selection sheet
struct UniversalActionSheet: View {
    let screenshot: Screenshot

    /// Photo library service
    private let photoLibraryService = PhotoLibraryService.shared

    /// Image state
    @State private var image: UIImage?

    /// Alert state
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    /// Contact to save
    @State private var contactToSave: CNMutableContact?
    @State private var showingContactView = false

    /// Dismiss environment
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                // Screenshot preview section
                Section {
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 200)
                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    }
                } header: {
                    Text("Screenshot")
                } footer: {
                    Text("Select any action - the app will extract relevant information automatically")
                }

                // Actions section
                Section {
                    ActionRow(
                        icon: "person.crop.circle.badge.plus",
                        title: "Save Contact",
                        description: "Create a new contact",
                        canPerform: canSaveContact(),
                        action: { performSaveContact() }
                    )

                    ActionRow(
                        icon: "note.text.badge.plus",
                        title: "Create Note",
                        description: "Create a new note with text/image",
                        canPerform: canCreateNote(),
                        action: { performCreateNote() }
                    )

                    ActionRow(
                        icon: "calendar.badge.plus",
                        title: "Add to Calendar",
                        description: "Create a calendar event",
                        canPerform: canAddToCalendar(),
                        action: { performAddToCalendar() }
                    )

                    ActionRow(
                        icon: "bookmark.fill",
                        title: "Save Bookmark",
                        description: "Save URL to Reading List",
                        canPerform: canSaveBookmark(),
                        action: { performSaveBookmark() }
                    )

                    ActionRow(
                        icon: "link",
                        title: "Open Link",
                        description: "Open URL in Safari",
                        canPerform: canOpenURL(),
                        action: { performOpenURL() }
                    )

                    ActionRow(
                        icon: "map.fill",
                        title: "Open in Maps",
                        description: "Open address in Maps app",
                        canPerform: canOpenMap(),
                        action: { performOpenMap() }
                    )

                    ActionRow(
                        icon: "phone.fill",
                        title: "Make Call",
                        description: "Call a phone number",
                        canPerform: canMakeCall(),
                        action: { performMakeCall() }
                    )

                    ActionRow(
                        icon: "envelope.fill",
                        title: "Send Email",
                        description: "Compose email",
                        canPerform: canSendEmail(),
                        action: { performSendEmail() }
                    )

                    ActionRow(
                        icon: "doc.on.doc",
                        title: "Copy Text",
                        description: "Copy all text to clipboard",
                        canPerform: canCopyText(),
                        action: { performCopyText() }
                    )

                    ActionRow(
                        icon: "photo.on.rectangle.angled",
                        title: "Save to Photos",
                        description: "Save screenshot to Photos library",
                        canPerform: true, // Always available
                        action: { performSaveToPhotos() }
                    )

                    ActionRow(
                        icon: "square.and.arrow.up",
                        title: "Share Image",
                        description: "Share screenshot",
                        canPerform: true, // Always available
                        action: { performShareImage() }
                    )
                } header: {
                    Text("Choose Action")
                }
            }
            .navigationTitle("Actions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
        .onAppear {
            loadImage()
        }
        .sheet(isPresented: $showingContactView) {
            if let contact = contactToSave {
                ContactViewController(contact: contact) {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Image Loading

    private func loadImage() {
        photoLibraryService.fetchFullImage(for: screenshot) { loadedImage in
            image = loadedImage
        }
    }

    // MARK: - Validation Methods

    private func canSaveContact() -> Bool {
        guard let extracted = screenshot.extractedData else { return false }
        return extracted.contactName != nil ||
               !extracted.emails.isEmpty ||
               !extracted.phoneNumbers.isEmpty
    }

    private func canCreateNote() -> Bool {
        guard let text = screenshot.extractedData?.fullText?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return false
        }
        return text.count >= 20
    }

    private func canAddToCalendar() -> Bool {
        guard let extracted = screenshot.extractedData else { return false }
        return extracted.eventName != nil || extracted.eventDate != nil
    }

    private func canSaveBookmark() -> Bool {
        guard let extracted = screenshot.extractedData else { return false }
        return !extracted.urls.isEmpty
    }

    private func canOpenURL() -> Bool {
        guard let extracted = screenshot.extractedData else { return false }
        return !extracted.urls.isEmpty
    }

    private func canOpenMap() -> Bool {
        guard let extracted = screenshot.extractedData else { return false }
        return !extracted.addresses.isEmpty || extracted.eventLocation != nil
    }

    private func canMakeCall() -> Bool {
        guard let extracted = screenshot.extractedData else { return false }
        return !extracted.phoneNumbers.isEmpty || extracted.contactPhone != nil
    }

    private func canSendEmail() -> Bool {
        guard let extracted = screenshot.extractedData else { return false }
        return !extracted.emails.isEmpty || extracted.contactEmail != nil
    }

    private func canCopyText() -> Bool {
        guard let extracted = screenshot.extractedData else { return false }
        return extracted.fullText != nil && !(extracted.fullText?.isEmpty ?? true)
    }

    // MARK: - Action Execution Methods

    private func performSaveContact() {
        guard let extracted = screenshot.extractedData else {
            showAlert(title: "Cannot Save Contact", message: "No contact information found on this screenshot")
            return
        }

        // Create contact
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

        // Show contact view controller
        contactToSave = contact
        showingContactView = true
    }

    private func performCreateNote() {
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

        presentNoteShareSheet(with: fullText)
    }

    private func presentNoteShareSheet(with text: String) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootVC = window.rootViewController else {
            showAlert(title: "Cannot Share", message: "Unable to present share sheet")
            return
        }

        let activityVC = UIActivityViewController(
            activityItems: [NoteTextActivityItemSource(text: text)],
            applicationActivities: nil
        )

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
        dismiss()
    }

    private func performAddToCalendar() {
        guard let extracted = screenshot.extractedData else {
            showAlert(title: "Cannot Add to Calendar", message: "No event information found on this screenshot")
            return
        }

        let eventStore = EKEventStore()

        // Request calendar access
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
                        showAlert(title: "Event Created", message: "Event added to your calendar successfully")
                        dismiss()
                    }
                } else {
                    await MainActor.run {
                        showAlert(title: "Permission Denied", message: "Calendar access is required to add events")
                    }
                }
            } catch {
                await MainActor.run {
                    showAlert(title: "Error", message: "Failed to create event: \(error.localizedDescription)")
                }
            }
        }
    }

    private func performSaveBookmark() {
        guard let extracted = screenshot.extractedData,
              let firstURL = extracted.urls.first,
              let url = URL(string: firstURL) else {
            showAlert(title: "Cannot Save Bookmark", message: "No URL found on this screenshot")
            return
        }

        // Use Safari's Reading List
        // Note: Direct bookmark saving requires private APIs
        // Reading List is the official way to save for later
        let readingListURL = URL(string: "x-safari-reading-list:\(url.absoluteString)")

        if let readingListURL = readingListURL {
            UIApplication.shared.open(readingListURL) { success in
                if !success {
                    DispatchQueue.main.async {
                        self.showAlert(title: "Bookmark Saved", message: "URL: \(firstURL)\n\nYou can manually add this to Safari bookmarks.")
                    }
                }
            }
        }

        dismiss()
    }

    private func performOpenURL() {
        guard let extracted = screenshot.extractedData,
              let firstURL = extracted.urls.first,
              let url = URL(string: firstURL) else {
            showAlert(title: "Cannot Open Link", message: "No URL found on this screenshot")
            return
        }

        // Open URL in Safari
        UIApplication.shared.open(url)
        dismiss()
    }

    private func performOpenMap() {
        guard let extracted = screenshot.extractedData else {
            showAlert(title: "Cannot Open Map", message: "No address found on this screenshot")
            return
        }

        let address = extracted.addresses.first ?? extracted.eventLocation ?? ""

        if let encoded = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: "http://maps.apple.com/?q=\(encoded)") {
            UIApplication.shared.open(url)
            dismiss()
        } else {
            showAlert(title: "Error", message: "Invalid address format")
        }
    }

    private func performMakeCall() {
        guard let extracted = screenshot.extractedData else {
            showAlert(title: "Cannot Make Call", message: "No phone number found on this screenshot")
            return
        }

        let phoneNumber = extracted.phoneNumbers.first ?? extracted.contactPhone ?? ""
        let cleaned = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()

        if let url = URL(string: "tel://\(cleaned)") {
            UIApplication.shared.open(url)
            dismiss()
        } else {
            showAlert(title: "Error", message: "Invalid phone number format")
        }
    }

    private func performSendEmail() {
        guard let extracted = screenshot.extractedData else {
            showAlert(title: "Cannot Send Email", message: "No email address found on this screenshot")
            return
        }

        let email = extracted.emails.first ?? extracted.contactEmail ?? ""

        if let url = URL(string: "mailto:\(email)") {
            UIApplication.shared.open(url)
            dismiss()
        } else {
            showAlert(title: "Error", message: "Invalid email address format")
        }
    }

    private func performCopyText() {
        guard let extracted = screenshot.extractedData,
              let text = extracted.fullText, !text.isEmpty else {
            showAlert(title: "Cannot Copy Text", message: "No text found on this screenshot")
            return
        }

        UIPasteboard.general.string = text
        showAlert(title: "Text Copied", message: "Text copied to clipboard successfully")
        dismiss()
    }

    private func performSaveToPhotos() {
        guard let image = image else {
            showAlert(title: "Cannot Save", message: "Image not loaded yet")
            return
        }

        // Save to Photos library using PHPhotoLibrary
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
                        self.showAlert(title: "Saved", message: "Screenshot saved to Photos library successfully")
                        self.dismiss()
                    } else if let error = error {
                        self.showAlert(title: "Save Failed", message: "Failed to save image: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    private func performShareImage() {
        guard let image = image else {
            showAlert(title: "Cannot Share", message: "Image not loaded yet")
            return
        }

        // Show share sheet
        let activityVC = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }

    // MARK: - Helper Methods

    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
}

// MARK: - Action Row

/// Row displaying a single action
struct ActionRow: View {
    let icon: String
    let title: String
    let description: String
    let canPerform: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 32)

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundColor(.primary)

                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Status indicator
                if canPerform {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundColor(.orange)
                }
            }
            .padding(.vertical, 4)
        }
        .disabled(!canPerform)
        .buttonStyle(.plain)
    }
}
