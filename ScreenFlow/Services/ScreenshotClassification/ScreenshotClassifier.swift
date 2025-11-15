//
//  ScreenshotClassifier.swift
//  ScreenFlow
//
//  Custom ML-based screenshot type classification
//

import Foundation
import Vision
import CoreML
import CoreGraphics

/// Screenshot classification result
struct ScreenshotClassification {
    let type: ScreenshotType
    let confidence: Float
    let allPredictions: [(type: ScreenshotType, confidence: Float)]
}

/// Supported screenshot types
enum ScreenshotType: String, CaseIterable {
    case businessCard = "BusinessCard"
    case creditCard = "CreditCard"
    case websitePage = "WebsitePage"
    case socialMediaPost = "SocialMediaPost"
    case appScreen = "AppScreen"
    case chatMessage = "ChatMessage"
    case productPage = "ProductPage"
    case discountCard = "DiscountCard"
    case memberCard = "MemberCard"
    case textDocument = "TextDocument"
    case handwrittenText = "HandwrittenText"
    case poster = "Poster"
    case videoFrame = "VideoFrame"
    case photo = "Photo"
    case other = "Other"

    var displayName: String {
        switch self {
        case .businessCard: return "Business Card"
        case .creditCard: return "Credit Card"
        case .websitePage: return "Website"
        case .socialMediaPost: return "Social Media"
        case .appScreen: return "App Screen"
        case .chatMessage: return "Chat"
        case .productPage: return "Product"
        case .discountCard: return "Discount Card"
        case .memberCard: return "Member Card"
        case .textDocument: return "Document"
        case .handwrittenText: return "Handwriting"
        case .poster: return "Poster"
        case .videoFrame: return "Video"
        case .photo: return "Photo"
        case .other: return "Screenshot"
        }
    }
}

/// ML-powered screenshot classifier
final class ScreenshotClassifier {
    static let shared = ScreenshotClassifier()

    // MARK: - Configuration

    /// Name of your trained Core ML model
    /// After training in Create ML, add the .mlmodel file to the project
    /// and update this name to match
    private let modelName = "ScreenshotTypeClassifier"

    /// Whether the custom model is available
    private var isModelAvailable: Bool {
        return NSClassFromString(modelName) != nil
    }

    private init() {}

    // MARK: - Public API

    /// Classify screenshot type using ML model
    /// Falls back to heuristic classification if model not available
    func classify(_ cgImage: CGImage, text: String? = nil) async -> ScreenshotClassification {
        // Try ML-based classification first
        if isModelAvailable {
            if let mlResult = await classifyWithML(cgImage) {
                print("✅ ML Classification: \(mlResult.type.displayName) (confidence: \(Int(mlResult.confidence * 100))%)")
                return mlResult
            }
        }

        // Fallback to heuristic classification
        print("⚠️ ML model not available, using heuristic classification")
        return await classifyWithHeuristics(cgImage, text: text)
    }

    // MARK: - ML Classification

    /// Classify using custom trained Core ML model
    private func classifyWithML(_ cgImage: CGImage) async -> ScreenshotClassification? {
        return await withCheckedContinuation { continuation in
            // TEMPLATE: Uncomment when you add your trained model
            /*
            guard let model = try? ScreenshotTypeClassifier(configuration: MLModelConfiguration()),
                  let visionModel = try? VNCoreMLModel(for: model.model) else {
                print("❌ Failed to load ScreenshotTypeClassifier model")
                continuation.resume(returning: nil)
                return
            }

            let request = VNCoreMLRequest(model: visionModel) { request, error in
                guard error == nil,
                      let results = request.results as? [VNClassificationObservation],
                      let topResult = results.first else {
                    continuation.resume(returning: nil)
                    return
                }

                // Parse classification results
                let type = ScreenshotType(rawValue: topResult.identifier) ?? .other
                let allPredictions = results.prefix(5).compactMap { obs -> (ScreenshotType, Float)? in
                    guard let type = ScreenshotType(rawValue: obs.identifier) else { return nil }
                    return (type, obs.confidence)
                }

                let classification = ScreenshotClassification(
                    type: type,
                    confidence: topResult.confidence,
                    allPredictions: allPredictions
                )

                continuation.resume(returning: classification)
            }

            request.imageCropAndScaleOption = .centerCrop

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                print("❌ ML classification failed: \(error.localizedDescription)")
                continuation.resume(returning: nil)
            }
            */

            // Until model is added, return nil
            continuation.resume(returning: nil)
        }
    }

    // MARK: - Heuristic Fallback

    /// Classify using heuristics (fallback when ML model not available)
    private func classifyWithHeuristics(_ cgImage: CGImage, text: String?) async -> ScreenshotClassification {
        // First check if text indicates social media (high confidence)
        if let text = text, let socialMediaResult = detectSocialMedia(from: text) {
            return socialMediaResult
        }

        // Use existing Vision scene classification as fallback
        return await withCheckedContinuation { continuation in
            let request = VNClassifyImageRequest { request, error in
                guard error == nil,
                      let results = request.results as? [VNClassificationObservation] else {
                    continuation.resume(returning: ScreenshotClassification(
                        type: .other,
                        confidence: 0.0,
                        allPredictions: []
                    ))
                    return
                }

                // Map scene classification to screenshot types
                let type = self.mapSceneToScreenshotType(results, text: text)
                let confidence = results.first?.confidence ?? 0.0

                continuation.resume(returning: ScreenshotClassification(
                    type: type,
                    confidence: confidence,
                    allPredictions: [(type, confidence)]
                ))
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: ScreenshotClassification(
                    type: .other,
                    confidence: 0.0,
                    allPredictions: []
                ))
            }
        }
    }

    /// Map Vision scene classification to screenshot types
    private func mapSceneToScreenshotType(_ results: [VNClassificationObservation], text: String?) -> ScreenshotType {
        let topScenes = results.prefix(3).map { $0.identifier.lowercased() }

        // Check for specific patterns
        for scene in topScenes {
            if scene.contains("text") || scene.contains("document") {
                return .textDocument
            }
            if scene.contains("conversation") || scene.contains("message") {
                return .chatMessage
            }
            if scene.contains("interface") || scene.contains("screen") {
                return .appScreen
            }
            if scene.contains("web") || scene.contains("browser") {
                return .websitePage
            }
            if scene.contains("poster") || scene.contains("advertisement") {
                return .poster
            }
            if scene.contains("photo") || scene.contains("picture") {
                return .photo
            }
        }

        return .other
    }

    /// Detect social media posts from text patterns
    private func detectSocialMedia(from text: String) -> ScreenshotClassification? {
        let lowerText = text.lowercased()
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        var confidence: Float = 0.0
        var indicators = 0

        // Check for social media UI indicators
        let socialMediaIndicators = [
            "views", "likes", "comments", "share", "retweet", "reply",
            "follow", "followers", "following", "subscribe", "subscribers",
            "ago", "posted", "shared", "retweeted", "commented"
        ]

        for indicator in socialMediaIndicators {
            if lowerText.contains(indicator) {
                indicators += 1
                confidence += 0.15
            }
        }

        // Check for post timestamp patterns at the beginning
        if let firstLine = lines.first {
            let timestampPatterns = [
                #"\d{1,2}/\d{1,2}/\d{2,4}"#,  // 27/1/25
                #"\d{1,2}[hmd]\s*ago"#,         // 2h ago, 5m ago, 3d ago
                #"(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s+\d{1,2}"#  // Jan 27
            ]

            for pattern in timestampPatterns {
                if firstLine.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil,
                   firstLine.count < 20 {
                    confidence += 0.3
                    indicators += 1
                    break
                }
            }
        }

        // Check for social media platform names
        let platformNames = [
            "twitter", "facebook", "instagram", "threads", "tiktok",
            "linkedin", "reddit", "youtube", "snapchat", "mastodon"
        ]

        for platform in platformNames {
            if lowerText.contains(platform) {
                confidence += 0.4
                indicators += 2
                break
            }
        }

        // Need at least 2 indicators or high confidence
        guard indicators >= 2 || confidence >= 0.5 else {
            return nil
        }

        // Cap confidence at 1.0
        confidence = min(confidence, 1.0)

        return ScreenshotClassification(
            type: .socialMediaPost,
            confidence: confidence,
            allPredictions: [(.socialMediaPost, confidence)]
        )
    }
}
