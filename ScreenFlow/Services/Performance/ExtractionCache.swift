//
//  ExtractionCache.swift
//  ScreenFlow
//
//  Caches extraction results to avoid reprocessing
//

import Foundation

/// Cache for extraction results
actor ExtractionCache {
    private var cache: [String: CacheEntry] = [:]
    private let maxCacheSize: Int
    private let cacheExpirationTime: TimeInterval

    struct CacheEntry {
        let timestamp: Date
        let isCompleted: Bool
    }

    init(maxCacheSize: Int = 100, cacheExpirationTime: TimeInterval = 86400) { // 24 hours
        self.maxCacheSize = maxCacheSize
        self.cacheExpirationTime = cacheExpirationTime
    }

    /// Check if extraction is cached and still valid
    func isCached(_ assetIdentifier: String) -> Bool {
        guard let entry = cache[assetIdentifier] else {
            return false
        }

        // Check if cache expired
        let age = Date().timeIntervalSince(entry.timestamp)
        if age > cacheExpirationTime {
            cache.removeValue(forKey: assetIdentifier)
            return false
        }

        return entry.isCompleted
    }

    /// Mark extraction as completed
    func markCompleted(_ assetIdentifier: String) {
        // Enforce cache size limit
        if cache.count >= maxCacheSize {
            // Remove oldest entry
            if let oldestKey = cache.min(by: { $0.value.timestamp < $1.value.timestamp })?.key {
                cache.removeValue(forKey: oldestKey)
            }
        }

        cache[assetIdentifier] = CacheEntry(timestamp: Date(), isCompleted: true)
    }

    /// Clear entire cache
    func clear() {
        cache.removeAll()
    }

    /// Remove specific entry
    func remove(_ assetIdentifier: String) {
        cache.removeValue(forKey: assetIdentifier)
    }

    /// Get cache statistics
    func getStats() -> (count: Int, oldestAge: TimeInterval?) {
        let count = cache.count
        let oldestAge = cache.values.map { Date().timeIntervalSince($0.timestamp) }.max()
        return (count, oldestAge)
    }
}
