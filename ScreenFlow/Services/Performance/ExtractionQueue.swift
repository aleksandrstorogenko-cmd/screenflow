//
//  ExtractionQueue.swift
//  ScreenFlow
//
//  Manages concurrent extraction tasks to prevent memory overload
//

import Foundation

/// Actor-based queue for managing concurrent screenshot extractions
actor ExtractionQueue {
    private var activeCount = 0
    private let maxConcurrent: Int
    private var waitingTasks: [CheckedContinuation<Void, Never>] = []

    init(maxConcurrent: Int = 2) {
        self.maxConcurrent = maxConcurrent
    }

    /// Wait for a slot to become available
    func waitForSlot() async {
        while activeCount >= maxConcurrent {
            await withCheckedContinuation { continuation in
                waitingTasks.append(continuation)
            }
        }
        activeCount += 1
    }

    /// Release a slot and resume waiting tasks
    func releaseSlot() {
        activeCount -= 1

        // Resume one waiting task if any
        if !waitingTasks.isEmpty {
            let continuation = waitingTasks.removeFirst()
            continuation.resume()
        }
    }

    /// Get current queue status
    func getStatus() -> (active: Int, waiting: Int) {
        return (activeCount, waitingTasks.count)
    }
}
