//
//  PhotoLibraryService.swift
//  ScreenFlow
//
//  Service for managing photo library operations and screenshot synchronization
//

import Photos
import SwiftData
import UIKit
import Combine

/// Service responsible for fetching screenshots from photo library and syncing with SwiftData
@MainActor
final class PhotoLibraryService: ObservableObject {
    /// Singleton instance
    static let shared = PhotoLibraryService()

    /// Image manager for fetching images and thumbnails
    private let imageManager = PHCachingImageManager()

    /// Thumbnail size for list view
    let thumbnailSize = CGSize(width: 60, height: 60)

    /// Permission service dependency
    private let permissionService = PermissionService.shared

    /// Title generator service dependency
    private let titleGeneratorService = TitleGeneratorService()

    private init() {}

    // MARK: - Permission & Sync

    /// Check if app has photo library permission
    /// - Returns: Boolean indicating if access is granted
    func hasPermission() -> Bool {
        return permissionService.hasPermission()
    }

    /// Request permission and sync screenshots if granted
    /// - Parameter modelContext: SwiftData model context
    /// - Returns: Boolean indicating if permission was granted and sync completed
    func requestPermissionAndSync(modelContext: ModelContext) async -> Bool {
        let granted = await permissionService.requestPermission()

        if granted {
            await syncScreenshots(modelContext: modelContext)
        }

        return granted
    }

    // MARK: - Screenshot Management

    /// Fetch all screenshots from the photo library
    /// - Returns: Array of PHAsset representing screenshots
    func fetchScreenshots() -> [PHAsset] {
        // Create fetch options
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        // Fetch the screenshots smart album
        let screenshotCollections = PHAssetCollection.fetchAssetCollections(
            with: .smartAlbum,
            subtype: .smartAlbumScreenshots,
            options: nil
        )

        guard let screenshotCollection = screenshotCollections.firstObject else {
            return []
        }

        // Fetch all assets in the screenshots collection
        let assets = PHAsset.fetchAssets(in: screenshotCollection, options: fetchOptions)

        var screenshots: [PHAsset] = []
        assets.enumerateObjects { asset, _, _ in
            screenshots.append(asset)
        }

        return screenshots
    }

    /// Sync screenshots from photo library to SwiftData
    /// - Parameter modelContext: SwiftData model context
    func syncScreenshots(modelContext: ModelContext) async {
        let assets = fetchScreenshots()

        // Fetch existing screenshots from database
        let descriptor = FetchDescriptor<Screenshot>()
        let existingScreenshots = (try? modelContext.fetch(descriptor)) ?? []

        // Create a set of photo library asset identifiers
        let photoLibraryIdentifiers = Set(assets.map { $0.localIdentifier })

        // Create a set of existing asset identifiers for fast lookup
        let existingIdentifiers = Set(existingScreenshots.map { $0.assetIdentifier })

        // 1) Add new screenshots that don't exist in the database
        // Title generation happens on-demand when items become visible
        for asset in assets {
            let identifier = asset.localIdentifier

            if !existingIdentifiers.contains(identifier) {
                let screenshot = Screenshot(
                    assetIdentifier: identifier,
                    fileName: asset.value(forKey: "filename") as? String ?? "Unknown",
                    creationDate: asset.creationDate ?? Date(),
                    width: asset.pixelWidth,
                    height: asset.pixelHeight
                )

                modelContext.insert(screenshot)
            }
        }

        // 2) Remove screenshots that no longer exist in photo library
        for screenshot in existingScreenshots {
            if !photoLibraryIdentifiers.contains(screenshot.assetIdentifier) {
                modelContext.delete(screenshot)
            }
        }

        // Save the context
        try? modelContext.save()
    }

    /// Generate title for screenshot if it doesn't have one
    /// - Parameters:
    ///   - screenshot: Screenshot to analyze
    ///   - modelContext: SwiftData model context
    func generateTitleIfNeeded(for screenshot: Screenshot, modelContext: ModelContext) async {
        // Skip if already has a title
        guard screenshot.title == nil else { return }

        // Get the asset
        guard let asset = getAsset(for: screenshot.assetIdentifier) else { return }

        // Analyze and generate title
        await analyzeScreenshot(screenshot, asset: asset)

        // Save the context
        try? modelContext.save()
    }

    /// Analyze screenshot using Vision and set title/kind fields
    /// - Parameters:
    ///   - screenshot: Screenshot model to update
    ///   - asset: PHAsset to analyze
    private func analyzeScreenshot(_ screenshot: Screenshot, asset: PHAsset) async {
        await withCheckedContinuation { continuation in
            autoreleasepool {
                let options = PHImageRequestOptions()
                options.deliveryMode = .opportunistic
                options.isSynchronous = true
                options.resizeMode = .exact

                // Good balance between quality and memory (Vision needs clear text)
                let targetSize = CGSize(width: 1536, height: 1536)

                imageManager.requestImage(
                    for: asset,
                    targetSize: targetSize,
                    contentMode: .aspectFit,
                    options: options
                ) { [weak self] image, _ in
                    autoreleasepool {
                        guard let self = self,
                              let image = image,
                              let cgImage = image.cgImage else {
                            continuation.resume()
                            return
                        }

                        // Generate title using Vision
                        do {
                            let result = try self.titleGeneratorService.makeTitle(
                                for: cgImage,
                                captureDate: screenshot.creationDate
                            )
                            screenshot.title = result.title
                            screenshot.kind = result.kind.rawValue
                        } catch {
                            // If analysis fails, leave title and kind as nil
                            print("Failed to analyze screenshot: \(error)")
                        }

                        continuation.resume()
                    }
                }
            }
        }
    }

    /// Get PHAsset for a given asset identifier
    /// - Parameter identifier: Asset local identifier
    /// - Returns: PHAsset if found, nil otherwise
    func getAsset(for identifier: String) -> PHAsset? {
        let fetchOptions = PHFetchOptions()
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: fetchOptions)
        return assets.firstObject
    }

    /// Fetch thumbnail image for a screenshot
    /// - Parameters:
    ///   - screenshot: Screenshot model
    ///   - targetSize: Size of the thumbnail
    ///   - completion: Completion handler with UIImage
    func fetchThumbnail(
        for screenshot: Screenshot,
        targetSize: CGSize = CGSize(width: 60, height: 60),
        completion: @escaping (UIImage?) -> Void
    ) {
        guard let asset = getAsset(for: screenshot.assetIdentifier) else {
            completion(nil)
            return
        }

        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isSynchronous = false

        imageManager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }

    /// Fetch full-size image for a screenshot
    /// - Parameters:
    ///   - screenshot: Screenshot model
    ///   - completion: Completion handler with UIImage
    func fetchFullImage(
        for screenshot: Screenshot,
        completion: @escaping (UIImage?) -> Void
    ) {
        guard let asset = getAsset(for: screenshot.assetIdentifier) else {
            completion(nil)
            return
        }

        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isSynchronous = false

        imageManager.requestImage(
            for: asset,
            targetSize: PHImageManagerMaximumSize,
            contentMode: .aspectFit,
            options: options
        ) { image, _ in
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }

    /// Delete screenshots from app database (not from photo library)
    /// - Parameters:
    ///   - screenshots: Array of screenshots to delete
    ///   - modelContext: SwiftData model context
    func deleteFromApp(screenshots: [Screenshot], modelContext: ModelContext) {
        for screenshot in screenshots {
            modelContext.delete(screenshot)
        }
        try? modelContext.save()
    }
}
