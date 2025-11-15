//
//  URLNormalizer.swift
//  ScreenFlow
//
//  Utilities for normalizing and validating URLs
//

import Foundation

/// Utilities for URL normalization and validation
struct URLNormalizer {

    /// Get normalized URLs from extracted data, removing duplicates
    static func normalizedURLs(from data: ExtractedData) -> [URL] {
        var seen = Set<URL>()
        var results: [URL] = []

        for rawValue in data.urls {
            guard let normalized = normalizedURL(from: rawValue) else { continue }

            if seen.insert(normalized).inserted {
                results.append(normalized)
            }
        }

        return results
    }

    /// Normalize a raw URL string to a valid URL
    static func normalizedURL(from rawValue: String) -> URL? {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        var candidate = trimmed
        let lowercased = candidate.lowercased()
        if !lowercased.hasPrefix("http://") && !lowercased.hasPrefix("https://") {
            candidate = "https://\(candidate)"
        }

        guard let url = URL(string: candidate),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else {
            return nil
        }

        return url
    }
}
