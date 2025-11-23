//
//  GlassButton.swift
//  ScreenFlow
//
//  A reusable button component with a glass morphism effect that adapts to iOS versions.
//

import SwiftUI

/// A reusable button component that renders with a glass effect on supported versions
/// and falls back to a translucent material style on older versions.
struct GlassButton<Content: View>: View {
    /// Defines the shape of the glass button
    enum ButtonShape {
        /// A capsule shape (fully rounded ends)
        case capsule
        /// A circle shape
        case circle
        /// A rounded rectangle with a specific corner radius
        case rounded(cornerRadius: CGFloat)
    }

    // MARK: - Properties

    /// The shape of the button
    private let shape: ButtonShape

    /// Horizontal padding for the button content
    private let horizontalPadding: CGFloat

    /// Vertical padding for the button content
    private let verticalPadding: CGFloat

    /// Foreground color for the content (fallback style)
    private let foregroundColor: Color?

    /// Action to perform when tapped
    private let action: () -> Void

    /// The button content
    private let content: Content

    // MARK: - Initialization

    /// Creates a new GlassButton instance
    /// - Parameters:
    ///   - shape: The shape of the button (default: .capsule)
    ///   - horizontalPadding: Horizontal padding around content (default: 16)
    ///   - verticalPadding: Vertical padding around content (default: 8)
    ///   - foregroundColor: Text/Icon color for non-glass fallback (default: .white)
    ///   - action: Closure to execute on tap
    ///   - content: View builder for the button label
    init(
        shape: ButtonShape = .capsule,
        horizontalPadding: CGFloat = 16,
        verticalPadding: CGFloat = 8,
        foregroundColor: Color? = .white,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.shape = shape
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
        self.foregroundColor = foregroundColor
        self.action = action
        self.content = content()
    }

    // MARK: - Computed Properties

    private var resolvedShape: AnyShape {
        switch shape {
        case .capsule:
            return AnyShape(Capsule())
        case .circle:
            return AnyShape(Circle())
        case .rounded(let radius):
            return AnyShape(RoundedRectangle(cornerRadius: radius))
        }
    }

    // MARK: - Body

    var body: some View {
        if #available(iOS 26.0, *) {
            switch shape {
            case .capsule:
                buttonContent
                    .glassEffect(in: .capsule)
            case .circle:
                buttonContent
                    .glassEffect(in: .circle)
            case .rounded(let radius):
                buttonContent
                    .glassEffect(in: .rect(cornerRadius: radius))
            }
        } else {
            Button(action: action) {
                content
                    .foregroundStyle(foregroundColor ?? .primary)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, verticalPadding)
                    .background(.ultraThinMaterial)
                    .clipShape(resolvedShape)
                    .overlay(
                        resolvedShape
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
            }
        }
    }

    private var buttonContent: some View {
        Button(action: action) {
            content
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, verticalPadding)
        }
        .buttonStyle(.plain)
    }
}
