//
//  ColorExtractor.swift
//  ScreenFlow
//
//  Helper for extracting dominant colors from image regions
//

import Foundation
import CoreGraphics
import UIKit

/// Extracts dominant colors from image regions
final class ColorExtractor {
    /// Color names mapping for common colors
    private static let colorNames: [(name: String, rgb: (r: CGFloat, g: CGFloat, b: CGFloat))] = [
        ("red", (255, 0, 0)),
        ("orange", (255, 165, 0)),
        ("yellow", (255, 255, 0)),
        ("green", (0, 255, 0)),
        ("blue", (0, 0, 255)),
        ("purple", (128, 0, 128)),
        ("pink", (255, 192, 203)),
        ("brown", (165, 42, 42)),
        ("black", (0, 0, 0)),
        ("white", (255, 255, 255)),
        ("gray", (128, 128, 128)),
        ("beige", (245, 245, 220)),
        ("navy", (0, 0, 128)),
        ("teal", (0, 128, 128)),
        ("olive", (128, 128, 0)),
        ("maroon", (128, 0, 0)),
        ("silver", (192, 192, 192)),
        ("gold", (255, 215, 0))
    ]

    /// Extract dominant color from bounding box region
    static func extractDominantColor(from cgImage: CGImage, boundingBox: CGRect) -> String? {
        // Convert Vision coordinates (0,0 = bottom-left) to CGImage coordinates (0,0 = top-left)
        let imageHeight = CGFloat(cgImage.height)
        let imageWidth = CGFloat(cgImage.width)

        let rect = CGRect(
            x: boundingBox.origin.x * imageWidth,
            y: (1.0 - boundingBox.origin.y - boundingBox.height) * imageHeight,
            width: boundingBox.width * imageWidth,
            height: boundingBox.height * imageHeight
        )

        // Crop to region
        guard let croppedImage = cgImage.cropping(to: rect) else {
            return nil
        }

        // Sample colors from the region
        guard let avgColor = averageColor(from: croppedImage) else {
            return nil
        }

        // Find nearest color name
        return nearestColorName(to: avgColor)
    }

    /// Calculate average color from image
    private static func averageColor(from cgImage: CGImage) -> (r: CGFloat, g: CGFloat, b: CGFloat)? {
        let width = cgImage.width
        let height = cgImage.height

        // Use a smaller sample size for performance
        let sampleWidth = min(width, 50)
        let sampleHeight = min(height, 50)

        guard let context = CGContext(
            data: nil,
            width: sampleWidth,
            height: sampleHeight,
            bitsPerComponent: 8,
            bytesPerRow: sampleWidth * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: sampleWidth, height: sampleHeight))

        guard let data = context.data else { return nil }

        let pixelBuffer = data.bindMemory(to: UInt8.self, capacity: sampleWidth * sampleHeight * 4)

        var totalRed: UInt64 = 0
        var totalGreen: UInt64 = 0
        var totalBlue: UInt64 = 0
        var pixelCount: UInt64 = 0

        for y in 0..<sampleHeight {
            for x in 0..<sampleWidth {
                let offset = (y * sampleWidth + x) * 4

                let red = UInt64(pixelBuffer[offset])
                let green = UInt64(pixelBuffer[offset + 1])
                let blue = UInt64(pixelBuffer[offset + 2])
                let alpha = UInt64(pixelBuffer[offset + 3])

                // Skip transparent pixels
                if alpha < 50 { continue }

                totalRed += red
                totalGreen += green
                totalBlue += blue
                pixelCount += 1
            }
        }

        guard pixelCount > 0 else { return nil }

        return (
            r: CGFloat(totalRed) / CGFloat(pixelCount),
            g: CGFloat(totalGreen) / CGFloat(pixelCount),
            b: CGFloat(totalBlue) / CGFloat(pixelCount)
        )
    }

    /// Find nearest color name
    private static func nearestColorName(to rgb: (r: CGFloat, g: CGFloat, b: CGFloat)) -> String {
        var minDistance = CGFloat.greatestFiniteMagnitude
        var nearestColor = "unknown"

        for (colorName, colorRGB) in colorNames {
            // Calculate Euclidean distance in RGB space
            let distance = sqrt(
                pow(rgb.r - colorRGB.r, 2) +
                pow(rgb.g - colorRGB.g, 2) +
                pow(rgb.b - colorRGB.b, 2)
            )

            if distance < minDistance {
                minDistance = distance
                nearestColor = colorName
            }
        }

        return nearestColor
    }
}
