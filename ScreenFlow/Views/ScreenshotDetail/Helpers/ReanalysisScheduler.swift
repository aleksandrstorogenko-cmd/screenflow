//
//  ReanalysisScheduler.swift
//  ScreenFlow
//
//  Manages debounced re-analysis of screenshots
//

import Foundation
import SwiftData

/// Manages debounced re-analysis scheduling for screenshots
class ReanalysisScheduler {
    /// Currently running re-analysis task
    private var reanalysisTask: Task<Void, Never>?

    /// Photo library service
    private let photoLibraryService = PhotoLibraryService.shared

    /// Schedule re-analysis with debouncing to prevent UI freeze
    func scheduleReanalysis(
        for screenshot: Screenshot,
        modelContext: ModelContext
    ) {
        // Cancel any existing analysis task
        reanalysisTask?.cancel()

        // Schedule new analysis with background priority to never interfere with UI
        reanalysisTask = Task(priority: .background) {
            // Wait 1.5 seconds to ensure scroll animation has completed
            try? await Task.sleep(nanoseconds: 1_500_000_000)

            // Check if task was cancelled during the delay
            guard !Task.isCancelled else { return }

            // Perform re-analysis in background
            await photoLibraryService.reanalyzeScreenshot(
                for: screenshot,
                modelContext: modelContext
            )
        }
    }

    /// Cancel any ongoing re-analysis
    func cancelReanalysis() {
        reanalysisTask?.cancel()
    }
}
