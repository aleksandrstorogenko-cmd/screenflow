//
//  BookmarkSelectionSheet.swift
//  ScreenFlow
//
//  Sheet for selecting which bookmarks to save
//

import SwiftUI

/// Sheet for selecting which URL bookmarks to save to Reading List
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
