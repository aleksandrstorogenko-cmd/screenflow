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

    /// State for showing compatibility alert
    @State private var showCompatibilityAlert = false

    /// Computed property to convert string to ProcessingType
    private var processingType: ProcessingType {
        ProcessingType(rawValue: selectedProcessingType) ?? .offline
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(ProcessingType.allCases) { type in
                        Button {
                            if type.isAvailable {
                                selectedProcessingType = type.rawValue
                            }
                        } label: {
                            ModelSelectionRow(
                                type: type,
                                isSelected: selectedProcessingType == type.rawValue,
                                onInfoTap: {
                                    showCompatibilityAlert = true
                                }
                            )
                        }
                        .disabled(!type.isAvailable)
                    }
                } header: {
                    Text("Model")
                        .textCase(.uppercase)
                } footer: {
                    if !processingType.isAvailable {
                        Text("Selected processing type is not available on this device")
                            .foregroundStyle(.red)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Apple Intelligence Not Available", isPresented: $showCompatibilityAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Apple Intelligence processing requires iOS 26 or later and is supported on iPhone 15 Pro, iPhone 15 Pro Max, and newer models with A17 Pro chip or later.")
            }
        }
    }
}

/// Individual row for model selection that matches Apple's settings design
private struct ModelSelectionRow: View {
    let type: ProcessingType
    let isSelected: Bool
    let onInfoTap: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Main content
            VStack(alignment: .leading, spacing: 2) {
                Text(type.displayName)
                    .font(.body)
                    .foregroundStyle(type.isAvailable ? .primary : .secondary)

                Text(type.description)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            // Trailing content with fixed width to prevent jumping
            HStack(spacing: 8) {
                if !type.isAvailable {
                    Button {
                        onInfoTap()
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                // Fixed width container for checkmark to prevent layout shifts
                ZStack {
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.tint)
                    }
                }
                .frame(width: 20, alignment: .trailing)
            }
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    SettingsView()
}
