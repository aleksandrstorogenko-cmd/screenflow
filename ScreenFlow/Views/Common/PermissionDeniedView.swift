//
//  PermissionDeniedView.swift
//  ScreenFlow
//
//  View displayed when photo library permission is denied
//

import SwiftUI

/// View shown when permission to access photo library is denied
struct PermissionDeniedView: View {
    /// Action to perform when grant access button is tapped
    let onGrantAccess: () async -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("Photo Library Access Required")
                .font(.title2)
                .bold()

            Text("This app needs access to your photo library to display screenshots.")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal)

            Button("Grant Access") {
                Task {
                    await onGrantAccess()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
