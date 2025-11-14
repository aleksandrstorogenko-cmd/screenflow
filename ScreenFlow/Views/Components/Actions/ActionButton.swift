//
//  ActionButton.swift
//  ScreenFlow
//
//  Button component for smart actions
//

import SwiftUI

/// Button for executing smart actions
struct ActionButton: View {
    let action: SmartAction
    let screenshot: Screenshot?

    @State private var isPerforming = false
    @State private var showSuccessIndicator = false
    @State private var showErrorIndicator = false

    var body: some View {
        Button {
            performAction()
        } label: {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: action.actionIcon)
                    .font(.title3)
                    .foregroundColor(.blue)
                    .frame(width: 32)

                // Title
                Text(action.actionTitle)
                    .font(.body)
                    .foregroundColor(.primary)

                Spacer()

                // Status indicator
                if isPerforming {
                    ProgressView()
                        .scaleEffect(0.8)
                } else if showSuccessIndicator {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else if showErrorIndicator {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(backgroundColor)
            .cornerRadius(12)
        }
        .disabled(isPerforming || !action.isEnabled)
        .padding(.horizontal)
    }

    // MARK: - Computed Properties

    private var backgroundColor: Color {
        if showSuccessIndicator {
            return Color.green.opacity(0.1)
        } else if showErrorIndicator {
            return Color.red.opacity(0.1)
        } else {
            return Color(.systemGray6)
        }
    }

    // MARK: - Methods

    private func performAction() {
        isPerforming = true
        showSuccessIndicator = false
        showErrorIndicator = false

        Task {
            let success = await ActionExecutor.shared.execute(action, screenshot: screenshot)

            isPerforming = false

            if success {
                showSuccessIndicator = true
                // Hide success indicator after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    showSuccessIndicator = false
                }
            } else {
                showErrorIndicator = true
                // Hide error indicator after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    showErrorIndicator = false
                }
            }
        }
    }
}
