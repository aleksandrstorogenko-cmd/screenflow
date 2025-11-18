//
//  SettingsView.swift
//  ScreenFlow
//
//  Settings screen for app configuration
//

import SwiftUI

/// Settings view for app configuration
struct SettingsView: View {
    /// Centralized storage for app settings backed by UserDefaults
    @AppSettingsStorage private var appSettings

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    AIProcessingSettingsSection(isEnabled: appSettings.useAIProcessingBinding)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    SettingsView()
}
