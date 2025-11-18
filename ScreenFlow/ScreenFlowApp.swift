//
//  ScreenFlowApp.swift
//  ScreenFlow
//
//  Main app entry point
//

import SwiftUI
import SwiftData

@main
struct ScreenFlowApp: App {
    /// SwiftData model container
    let modelContainer: ModelContainer

    init() {
        // Initialize SwiftData container with Screenshot model
        do {
            modelContainer = try ModelContainer(for: Screenshot.self)
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            AppTabView()
        }
        .modelContainer(modelContainer)
    }
}
