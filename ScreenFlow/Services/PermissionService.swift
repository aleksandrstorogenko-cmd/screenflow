//
//  PermissionService.swift
//  ScreenFlow
//
//  Service for managing photo library permissions
//

import Photos
import Foundation
import Combine

/// Service responsible for requesting and checking photo library access permissions
@MainActor
final class PermissionService: ObservableObject {
    /// Published property indicating current authorization status
    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined

    /// Singleton instance
    static let shared = PermissionService()

    private init() {
        // Check current authorization status
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    /// Request photo library access permission
    /// - Returns: Boolean indicating if access was granted
    func requestPermission() async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        authorizationStatus = status

        switch status {
        case .authorized, .limited:
            return true
        case .denied, .restricted, .notDetermined:
            return false
        @unknown default:
            return false
        }
    }

    /// Check if the app has permission to access the photo library
    /// - Returns: Boolean indicating if access is granted
    func hasPermission() -> Bool {
        switch authorizationStatus {
        case .authorized, .limited:
            return true
        case .denied, .restricted, .notDetermined:
            return false
        @unknown default:
            return false
        }
    }

    /// Check current authorization status and update the published property
    func checkAuthorizationStatus() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }
}
