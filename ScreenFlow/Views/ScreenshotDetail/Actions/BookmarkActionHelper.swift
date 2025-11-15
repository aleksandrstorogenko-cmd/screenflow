//
//  BookmarkActionHelper.swift
//  ScreenFlow
//
//  Helper for bookmark and Reading List actions
//

import Foundation
import SafariServices

/// Helper for saving bookmarks to Safari Reading List
/// TODO: Refactor to use ActionExecutor service instead of inline implementation
struct BookmarkActionHelper {

    /// Result of bookmark operation
    struct BookmarkResult {
        let savedCount: Int
        let totalCount: Int
        let failureMessages: [String]

        var title: String {
            if savedCount == totalCount {
                return "Bookmarks Saved"
            } else if savedCount > 0 {
                return "Partially Saved"
            } else {
                return "Unable to Save"
            }
        }

        var message: String {
            if savedCount == totalCount {
                return savedCount == 1
                    ? "URL added to Safari Reading List"
                    : "\(savedCount) URLs added to Safari Reading List"
            } else if savedCount > 0 {
                let details = failureMessages.joined(separator: "\n")
                return "Saved \(savedCount) of \(totalCount) link(s).\n\nFailed:\n\(details)"
            } else {
                let details = failureMessages.isEmpty ? "Unknown error" : failureMessages.joined(separator: "\n")
                return "Could not add to Reading List:\n\(details)"
            }
        }
    }

    /// Add bookmarks to Safari Reading List
    static func addBookmarksToReadingList(_ urls: [URL]) async -> BookmarkResult? {
        print("📚 Attempting to save \(urls.count) bookmark(s) to Reading List:")
        for (index, url) in urls.enumerated() {
            print("  \(index + 1). \(url.absoluteString)")
        }

        guard let readingList = SSReadingList.default() else {
            return nil
        }

        var savedCount = 0
        var failureMessages: [String] = []

        for (index, url) in urls.enumerated() {
            // Safari Reading List requires main thread access
            await MainActor.run {
                do {
                    try readingList.addItem(with: url, title: url.host, previewText: nil)
                    savedCount += 1
                    print("✅ Saved bookmark \(index + 1)/\(urls.count): \(url.absoluteString)")
                } catch {
                    let nsError = error as NSError
                    let reason: String
                    if nsError.domain == SSReadingListErrorDomain,
                       let code = SSReadingListError.Code(rawValue: nsError.code) {
                        switch code {
                        case .urlSchemeNotAllowed:
                            reason = "URL scheme not allowed"
                        default:
                            reason = nsError.localizedDescription
                        }
                    } else {
                        reason = nsError.localizedDescription
                    }
                    let shortURL = url.host ?? url.absoluteString
                    failureMessages.append("• \(shortURL): \(reason)")
                    print("❌ Failed to save bookmark \(index + 1)/\(urls.count): \(url.absoluteString) - \(reason)")
                }
            }

            // Safari Reading List needs significant delay between insertions to process them reliably
            // 150ms is too fast and causes Safari to silently drop URLs
            if index < urls.count - 1 {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
            }
        }

        return BookmarkResult(
            savedCount: savedCount,
            totalCount: urls.count,
            failureMessages: failureMessages
        )
    }
}
