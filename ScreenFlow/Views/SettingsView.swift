//
//  SettingsView.swift
//  ScreenFlow
//
//  Settings screen for app configuration
//

import SwiftUI

/// Settings view for app configuration
struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Settings coming soon...")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    SettingsView()
}
