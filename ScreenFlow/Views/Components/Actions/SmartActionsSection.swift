//
//  SmartActionsSection.swift
//  ScreenFlow
//
//  Section displaying smart actions for a screenshot
//

import SwiftUI

/// Section showing available smart actions
struct SmartActionsSection: View {
    let actions: [SmartAction]
    let screenshot: Screenshot?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            Text("Quick Actions")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top, 8)

            // Action buttons
            if actions.isEmpty {
                Text("No actions available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(actions.sorted(by: { $0.priority < $1.priority })) { action in
                        ActionButton(action: action, screenshot: screenshot)
                    }
                }
                .padding(.bottom, 8)
            }
        }
    }
}
