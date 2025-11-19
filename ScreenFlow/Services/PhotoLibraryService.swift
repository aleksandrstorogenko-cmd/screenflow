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

enum PhotoLibraryServiceError: LocalizedError {
    case assetNotFound
    case deletionFailed

    var errorDescription: String? {
        switch self {
        case .assetNotFound:
            return "Couldn't locate this screenshot in your photo library."
        case .deletionFailed:
            return "Failed to delete the screenshot. Please try again."
        }
    }
}

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

    /// Screenshot analysis service dependency (for classification and titles)
    private let screenshotAnalysisService = ScreenshotAnalysisService()

    /// Processing coordinator for the new pipeline
    private let processingCoordinator = ScreenshotProcessingCoordinator.shared

    /// Action generation service dependency
    private let actionGenerationService = ActionGenerationService.shared

    /// Extraction queue for limiting concurrent processing
    private let extractionQueue = ExtractionQueue(maxConcurrent: 2)

    /// Extraction cache to avoid reprocessing
    private let extractionCache = ExtractionCache()

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

        // Check cache - skip if already processed
        let isCached = await extractionCache.isCached(screenshot.assetIdentifier)
        if isCached { return }

        // Get the asset
        guard let asset = getAsset(for: screenshot.assetIdentifier) else { return }

        // Wait for a processing slot (limits concurrent extractions)
        await extractionQueue.waitForSlot()

        // Analyze and generate title
        await analyzeScreenshot(screenshot, asset: asset, modelContext: modelContext)

        // Mark as completed in cache
        await extractionCache.markCompleted(screenshot.assetIdentifier)

        // Release the slot
        await extractionQueue.releaseSlot()

        // Save the context
        try? modelContext.save()
    }

    /// Re-analyze screenshot (extract entities and generate actions, but keep title)
    /// - Parameters:
    ///   - screenshot: Screenshot to re-analyze
    ///   - modelContext: SwiftData model context
    func reanalyzeScreenshot(for screenshot: Screenshot, modelContext: ModelContext) async {
        // Get the asset
        guard let asset = getAsset(for: screenshot.assetIdentifier) else { return }

        // Wait for a processing slot (limits concurrent extractions)
        await extractionQueue.waitForSlot()

        // Re-analyze (extract entities and generate actions)
        await reanalyzeScreenshotData(screenshot, asset: asset, modelContext: modelContext)

        // Release the slot
        await extractionQueue.releaseSlot()

        // Save the context
        try? modelContext.save()
    }

    /// Analyze screenshot using Vision and set title/kind fields
    /// Also extracts entities and generates smart actions
    /// - Parameters:
    ///   - screenshot: Screenshot model to update
    ///   - asset: PHAsset to analyze
    ///   - modelContext: SwiftData model context
    private func analyzeScreenshot(_ screenshot: Screenshot, asset: PHAsset, modelContext: ModelContext) async {
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

                        // Analyze screenshot using new processing pipeline
                        // ✅ Run everything in a single MainActor task to ensure context consistency
                        Task { @MainActor in
                            do {
                                // Step 1: Classification and title generation
                                let classificationResult = try self.screenshotAnalysisService.makeTitle(
                                    for: cgImage,
                                    captureDate: screenshot.creationDate
                                )
                                screenshot.title = classificationResult.title
                                screenshot.kind = classificationResult.kind.rawValue

                                // Step 2: Process through new pipeline (OCR → Markdown → Entities)
                                let processedData = try await self.processingCoordinator.process(image: image)

                                // Convert pipeline output to SwiftData model
                                let extractedData = ExtractedDataAdapter.toSwiftDataModel(processedData)

                                // ✅ Insert into context BEFORE setting relationships
                                modelContext.insert(extractedData)

                                // Link to screenshot
                                extractedData.screenshot = screenshot
                                screenshot.extractedData = extractedData

                                // Generate smart actions
                                let actions = self.actionGenerationService.generateActions(from: extractedData)

                                // Link actions to screenshot
                                for action in actions {
                                    // ✅ Insert each action into context BEFORE setting relationships
                                    modelContext.insert(action)
                                    action.screenshot = screenshot
                                    screenshot.smartActions.append(action)
                                }

                                continuation.resume()
                            } catch {
                                // If processing fails, leave title and kind as nil
                                print("Failed to process screenshot: \(error)")
                                continuation.resume()
                            }
                        }
                    }
                }
            }
        }
    }

    /// Re-analyze screenshot data (extract entities and generate actions, but keep title)
    /// - Parameters:
    ///   - screenshot: Screenshot model to update
    ///   - asset: PHAsset to analyze
    ///   - modelContext: SwiftData model context
    private func reanalyzeScreenshotData(_ screenshot: Screenshot, asset: PHAsset, modelContext: ModelContext) async {
        await withCheckedContinuation { continuation in
            autoreleasepool {
                let options = PHImageRequestOptions()
                options.deliveryMode = .highQualityFormat
                options.isSynchronous = false  // Async to prevent blocking
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
                              let _ = image.cgImage else {
                            continuation.resume()
                            return
                        }

                        // Re-process through new pipeline
                        Task { @MainActor in
                            do {
                                // ✅ Explicitly delete old extracted data and actions to avoid backing data errors
                                // Must delete from context before setting relationships to nil
                                if let oldExtractedData = screenshot.extractedData {
                                    modelContext.delete(oldExtractedData)
                                    screenshot.extractedData = nil
                                }

                                // Delete all old smart actions
                                let oldActions = screenshot.smartActions
                                for action in oldActions {
                                    modelContext.delete(action)
                                }
                                screenshot.smartActions.removeAll()

                                // Process through new pipeline (OCR → Markdown → Entities)
                                let processedData = try await self.processingCoordinator.process(image: image)

                                // Convert pipeline output to SwiftData model
                                let extractedData = ExtractedDataAdapter.toSwiftDataModel(processedData)

                                // ✅ Insert into context BEFORE setting relationships
                                modelContext.insert(extractedData)

                                // Link to screenshot
                                extractedData.screenshot = screenshot
                                screenshot.extractedData = extractedData

                                // Generate smart actions
                                let actions = self.actionGenerationService.generateActions(from: extractedData)

                                // Link actions to screenshot
                                for action in actions {
                                    // ✅ Insert each action into context BEFORE setting relationships
                                    modelContext.insert(action)
                                    action.screenshot = screenshot
                                    screenshot.smartActions.append(action)
                                }

                                continuation.resume()
                            } catch {
                                // If processing fails, keep existing data
                                print("Failed to re-process screenshot through pipeline: \(error)")
                                continuation.resume()
                            }
                        }
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

    /// Delete screenshot from Photos library and from the app database
    /// - Parameters:
    ///   - screenshot: Screenshot to delete
    ///   - modelContext: SwiftData model context
    func deleteFromLibrary(_ screenshot: Screenshot, modelContext: ModelContext) async throws {
        guard let asset = getAsset(for: screenshot.assetIdentifier) else {
            throw PhotoLibraryServiceError.assetNotFound
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.deleteAssets([asset] as NSArray)
            }, completionHandler: { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume(returning: ())
                } else {
                    continuation.resume(throwing: PhotoLibraryServiceError.deletionFailed)
                }
            })
        }

        modelContext.delete(screenshot)
        try? modelContext.save()
    }
    
    /// Batch delete multiple screenshots from Photos library and from the app database
    /// - Parameters:
    ///   - screenshots: Array of screenshots to delete
    ///   - modelContext: SwiftData model context
    func batchDeleteFromLibrary(_ screenshots: [Screenshot], modelContext: ModelContext) async throws {
        let assets = screenshots.compactMap { getAsset(for: $0.assetIdentifier) }
        
        guard !assets.isEmpty else { return }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.deleteAssets(assets as NSArray)
            }, completionHandler: { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume(returning: ())
                } else {
                    continuation.resume(throwing: PhotoLibraryServiceError.deletionFailed)
                }
            })
        }
        
        for screenshot in screenshots {
            modelContext.delete(screenshot)
        }
        try? modelContext.save()
    }
}
