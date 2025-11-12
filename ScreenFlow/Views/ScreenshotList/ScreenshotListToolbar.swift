//
//  ScreenshotListToolbar.swift
//  ScreenFlow
//
//  Toolbar content for screenshot list view
//

import SwiftUI

/// Toolbar content for the screenshot list view
struct ScreenshotListToolbar: ToolbarContent {
    /// Edit mode binding
    @Binding var editMode: EditMode

    /// Filter option binding
    @Binding var showTodayOnly: Bool

    /// Selected screenshots
    @Binding var selectedScreenshots: Set<Screenshot.ID>

    /// Callback when selected screenshots should be deleted
    let onDeleteSelected: () -> Void

    var body: some ToolbarContent {
        // Delete button (shown in edit mode)
        if editMode == .active {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(role: .destructive) {
                    onDeleteSelected()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .disabled(selectedScreenshots.isEmpty)
            }
        }

        // Filter menu
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                Picker("Filter", selection: $showTodayOnly) {
                    Label("Today", systemImage: "calendar").tag(true)
                    Label("All", systemImage: "calendar.badge.clock").tag(false)
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease")
            }
        }

        // Select button
        ToolbarItem(placement: .cancellationAction) {
            Button {
                withAnimation {
                    if editMode == .active {
                        editMode = .inactive
                        selectedScreenshots.removeAll()
                    } else {
                        editMode = .active
                    }
                }
            } label: {
                Text(editMode == .active ? "Done" : "Select")
            }
        }
    }
}
