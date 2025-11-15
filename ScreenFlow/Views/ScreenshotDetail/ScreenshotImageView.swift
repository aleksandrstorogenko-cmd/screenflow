//
//  ScreenshotImageView.swift
//  ScreenFlow
//
//  View for displaying a single screenshot image with loading state
//

import SwiftUI

/// View for displaying a single screenshot image
struct ScreenshotImageView: View {
    let screenshot: Screenshot

    /// Photo library service
    private let photoLibraryService = PhotoLibraryService.shared

    /// Full-size image state
    @State private var fullImage: UIImage?

    /// Loading state
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .tint(.white)
            } else if let image = fullImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .ignoresSafeArea()
            } else {
                // Error state
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.white)

                    Text("Unable to load screenshot")
                        .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            loadFullImage()
        }
    }

    // MARK: - Methods

    /// Load full-size image
    private func loadFullImage() {
        photoLibraryService.fetchFullImage(for: screenshot) { image in
            fullImage = image
            isLoading = false
        }
    }
}
