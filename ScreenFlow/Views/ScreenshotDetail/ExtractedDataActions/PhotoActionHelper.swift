//
//  PhotoActionHelper.swift
//  ScreenFlow
//
//  Helper for photo-related actions (save, share)
//

import Foundation
import UIKit
import Photos

/// Helper for photo save and share actions
/// TODO: Refactor to use ActionExecutor service instead of inline implementation
struct PhotoActionHelper {

    /// Result of photo action
    enum Result {
        case success(title: String, message: String)
        case failure(title: String, message: String)
    }

    /// Save screenshot to Photos library
    static func saveToPhotos(screenshot: Screenshot, completion: @escaping (Result) -> Void) {
        PhotoLibraryService.shared.fetchFullImage(for: screenshot) { image in
            guard let image = image else {
                DispatchQueue.main.async {
                    completion(.failure(title: "Cannot Save", message: "Failed to load screenshot image"))
                }
                return
            }

            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                guard status == .authorized else {
                    DispatchQueue.main.async {
                        completion(.failure(title: "Permission Denied", message: "Photos access is required to save images"))
                    }
                    return
                }

                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                }) { success, error in
                    DispatchQueue.main.async {
                        if success {
                            completion(.success(title: "Saved to Photos", message: "Screenshot saved to your Photos library"))
                        } else if let error = error {
                            completion(.failure(title: "Save Failed", message: "Could not save: \(error.localizedDescription)"))
                        } else {
                            completion(.failure(title: "Save Failed", message: "An unknown error occurred"))
                        }
                    }
                }
            }
        }
    }

    /// Share screenshot image
    static func shareImage(screenshot: Screenshot, completion: @escaping (UIImage?) -> Void) {
        PhotoLibraryService.shared.fetchFullImage(for: screenshot) { image in
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }

    /// Present share sheet for image
    static func presentShareSheet(with image: UIImage) -> Bool {
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {

            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootVC.view
                popover.sourceRect = CGRect(
                    x: rootVC.view.bounds.midX,
                    y: rootVC.view.bounds.midY,
                    width: 0,
                    height: 0
                )
                popover.permittedArrowDirections = []
            }

            var topController = rootVC
            while let presented = topController.presentedViewController {
                topController = presented
            }

            topController.present(activityVC, animated: true)
            return true
        } else {
            return false
        }
    }
}
