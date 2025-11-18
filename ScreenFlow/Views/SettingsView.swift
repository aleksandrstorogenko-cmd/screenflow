//
//  SettingsView.swift
//  ScreenFlow
//
//  Settings screen for app configuration
//

import SwiftUI

/// Settings view for app configuration
struct SettingsView: View {
    /// Selected processing type stored in UserDefaults
    @AppStorage("processingType") private var selectedProcessingType: String = ProcessingType.offline.rawValue

    /// Computed property to convert string to ProcessingType
    private var processingType: ProcessingType {
        ProcessingType(rawValue: selectedProcessingType) ?? .offline
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Processing Type", selection: $selectedProcessingType) {
                        ForEach(ProcessingType.allCases) { type in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(type.displayName)
                                    .font(.body)
                                Text(type.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .tag(type.rawValue)
                            .disabled(!type.isAvailable)
                        }
                    }
                    .pickerStyle(.inline)
                } header: {
                    Text("Screenshot Processing")
                } footer: {
                    if !processingType.isAvailable {
                        Text("Selected processing type is not available on this device")
                            .foregroundStyle(.red)
                    }
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
