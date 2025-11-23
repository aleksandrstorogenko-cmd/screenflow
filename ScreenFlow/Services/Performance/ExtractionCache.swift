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
    private let fileURL: URL

    struct CacheEntry: Codable {
        let timestamp: Date
        let isCompleted: Bool
    }

    init(maxCacheSize: Int = 1000, cacheExpirationTime: TimeInterval = 86400) { // 24 hours
        self.maxCacheSize = maxCacheSize
        self.cacheExpirationTime = cacheExpirationTime
        
        // Setup file URL for persistence
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        self.fileURL = paths[0].appendingPathComponent("ExtractionCache.json")
        
        // Load cache from disk
        Task {
            await loadFromDisk()
        }
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
            saveToDisk() // Save after removal
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
        saveToDisk()
    }

    /// Clear entire cache
    func clear() {
        cache.removeAll()
        saveToDisk()
    }

    /// Remove specific entry
    func remove(_ assetIdentifier: String) {
        cache.removeValue(forKey: assetIdentifier)
        saveToDisk()
    }

    /// Get cache statistics
    func getStats() -> (count: Int, oldestAge: TimeInterval?) {
        let count = cache.count
        let oldestAge = cache.values.map { Date().timeIntervalSince($0.timestamp) }.max()
        return (count, oldestAge)
    }
    
    // MARK: - Persistence
    
    private func saveToDisk() {
        do {
            let data = try JSONEncoder().encode(cache)
            try data.write(to: fileURL)
        } catch {
            print("Failed to save extraction cache: \(error)")
        }
    }
    
    private func loadFromDisk() {
        do {
            guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
            let data = try Data(contentsOf: fileURL)
            cache = try JSONDecoder().decode([String: CacheEntry].self, from: data)
        } catch {
            print("Failed to load extraction cache: \(error)")
        }
    }
}
