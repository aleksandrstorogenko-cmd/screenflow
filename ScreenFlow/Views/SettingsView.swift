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
            ScrollView {
                // Scroll offset tracker at the top
                Color.clear
                    .frame(height: 0)
                    .readScrollOffset(coordinateSpace: "settingsScroll")

                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Model")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)

                        VStack(spacing: 0) {
                            ForEach(Array(ProcessingType.allCases.enumerated()), id: \.element.id) { index, type in
                                Button {
                                    if type.isAvailable {
                                        selectedProcessingType = type.rawValue
                                    }
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(type.displayName)
                                                .font(.body)
                                                .foregroundStyle(.primary)
                                            Text(type.description)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }

                                        Spacer()

                                        if selectedProcessingType == type.rawValue {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.blue)
                                                .font(.body.weight(.semibold))
                                        }
                                    }
                                    .padding()
                                    .background(Color(.secondarySystemGroupedBackground))
                                }
                                .disabled(!type.isAvailable)
                                .opacity(type.isAvailable ? 1 : 0.5)

                                if index < ProcessingType.allCases.count - 1 {
                                    Divider()
                                        .padding(.leading)
                                }
                            }
                        }
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(10)
                        .padding(.horizontal)

                        if !processingType.isAvailable {
                            Text("Selected processing type is not available on this device")
                                .font(.caption)
                                .foregroundStyle(.red)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.top)
                }
            }
            .coordinateSpace(name: "settingsScroll")
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    SettingsView()
}
