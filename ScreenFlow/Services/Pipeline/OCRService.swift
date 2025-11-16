//
//  OCRService.swift
//  ScreenFlow
//
//  Service for performing OCR on screenshots using Vision framework
//

import UIKit
import Vision

/// Service for extracting text from images using Vision OCR
final class OCRService: ScreenshotAnalysisServiceProtocol {

    // MARK: - Properties

    static let shared = OCRService()

    private init() {}

    // MARK: - ScreenshotAnalysisServiceProtocol

    /// Analyze an image and extract text with coordinates
    ///
    /// - Parameter image: The image to analyze
    /// - Returns: OCR result with blocks and raw text
    /// - Throws: Vision or processing errors
    func analyze(image: UIImage) async throws -> ScreenshotAnalysisResult {
        guard let cgImage = image.cgImage else {
            return ScreenshotAnalysisResult(ocrBlocks: [], rawText: "")
        }

        // Perform OCR
        let blocks = try await recognizeTextBlocks(in: cgImage)

        // Extract raw text in reading order
        let rawText = blocks.map { $0.text }.joined(separator: "\n")

        return ScreenshotAnalysisResult(
            ocrBlocks: blocks,
            rawText: rawText
        )
    }

    // MARK: - Private Methods

    /// Recognizes text blocks in an image using Vision framework
    ///
    /// - Parameter cgImage: The image to process
    /// - Returns: Array of OCR blocks with normalized coordinates (bottom-left origin, 0-1 range)
    /// - Throws: Vision processing errors
    private func recognizeTextBlocks(in cgImage: CGImage) async throws -> [OcrBlock] {
        // Create and configure text recognition request
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["en-US", "ru-RU", "uk-UA", "pl-PL", "es-ES", "de-DE", "fr-FR"]

        // Perform OCR
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        // Extract observations
        guard let observations = request.results else {
            return []
        }

        // Convert observations to OCR blocks
        let blocks = observations.compactMap { observation -> OcrBlock? in
            // Get best text candidate
            guard let text = observation.topCandidates(1).first?.string,
                  !text.isEmpty else {
                return nil
            }

            // Get bounding box (normalized, bottom-left origin)
            let rect = observation.boundingBox

            // Create OCR block
            return OcrBlock(
                text: text,
                x: Double(rect.origin.x),
                y: Double(rect.origin.y),
                width: Double(rect.size.width),
                height: Double(rect.size.height)
            )
        }

        // Sort by reading order (top to bottom, left to right)
        // Vision uses bottom-left origin, so larger y = higher on page
        return blocks.sorted { a, b in
            if abs(a.y - b.y) > 0.01 {
                return a.y > b.y  // Larger y first (visually higher)
            } else {
                return a.x < b.x  // Same row: left to right
            }
        }
    }
}
