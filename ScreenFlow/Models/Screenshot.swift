//
//  Screenshot.swift
//  ScreenFlow
//
//  SwiftData model for storing screenshot metadata
//

import Foundation
import SwiftData

/// Represents a screenshot with metadata stored in SwiftData
@Model
final class Screenshot {
    /// Unique identifier from PHAsset
    @Attribute(.unique) var assetIdentifier: String

    /// File name of the screenshot
    var fileName: String

    /// Date when the screenshot was created
    var creationDate: Date

    /// Width of the screenshot in pixels
    var width: Int

    /// Height of the screenshot in pixels
    var height: Int

    /// Flag indicating if this screenshot is marked for deletion in the app
    var isMarkedForDeletion: Bool

    /// Date when the screenshot was last synced from the photo library
    var lastSyncDate: Date

    /// Auto-generated inbox title for the screenshot
    var title: String?

    /// Screenshot classification type
    /// Possible values: "qr", "document", "link", "receipt", "businessCard", "chat", "text", "photo", "other"
    var kind: String?

    // MARK: - Relationships

    /// Extracted data from this screenshot
    @Relationship(deleteRule: .cascade, inverse: \ExtractedData.screenshot)
    var extractedData: ExtractedData?

    /// Smart actions generated for this screenshot
    @Relationship(deleteRule: .cascade, inverse: \SmartAction.screenshot)
    var smartActions: [SmartAction] = []

    // MARK: - Initialization

    /// Initialize a new Screenshot instance
    /// - Parameters:
    ///   - assetIdentifier: Unique PHAsset local identifier
    ///   - fileName: Name of the screenshot file
    ///   - creationDate: Date when screenshot was taken
    ///   - width: Width in pixels
    ///   - height: Height in pixels
    init(
        assetIdentifier: String,
        fileName: String,
        creationDate: Date,
        width: Int,
        height: Int
    ) {
        self.assetIdentifier = assetIdentifier
        self.fileName = fileName
        self.creationDate = creationDate
        self.width = width
        self.height = height
        self.isMarkedForDeletion = false
        self.lastSyncDate = Date()
        self.title = nil
        self.kind = nil
    }
}
