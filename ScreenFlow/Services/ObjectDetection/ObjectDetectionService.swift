//
//  ObjectDetectionService.swift
//  ScreenFlow
//
//  Service for detecting objects in screenshots using Vision and Core ML
//

import Foundation
import Vision
import CoreML
import CoreGraphics

/// Service for object detection
final class ObjectDetectionService {
    static let shared = ObjectDetectionService()

    // MARK: - Configuration

    /// Core ML model configuration
    /// Change this to use a different model after adding it to the project
    /// Available presets: .yolov8n, .mobilenetv3, .squeezenet
    /// Or create custom: .custom(modelName: "YourModel")
    private let modelConfig: CoreMLModelConfig? = .yolov8n
    // Example: private let modelConfig: CoreMLModelConfig? = .yolov8n

    private init() {}

    // MARK: - Public API

    /// Detect objects in image using built-in Vision detectors and optional Core ML model
    func detectObjects(in cgImage: CGImage) async -> [ObjectDetectionResult] {
        var results: [ObjectDetectionResult] = []

        // Use built-in Vision detectors (always available)
        let builtInResults = await detectWithBuiltInModels(cgImage: cgImage)
        results.append(contentsOf: builtInResults)

        // Custom Core ML model detection (if configured and available)
        if let config = modelConfig, config.isAvailable {
            let customResults = await detectWithCustomModel(cgImage: cgImage, config: config)
            results.append(contentsOf: customResults)
        }

        // Deduplicate results (in case built-in and custom models detect same objects)
        return deduplicateResults(results)
    }

    // MARK: - Built-in Detection

    /// Use built-in Vision detectors for animals and humans
    private func detectWithBuiltInModels(cgImage: CGImage) async -> [ObjectDetectionResult] {
        return await withCheckedContinuation { continuation in
            var results: [ObjectDetectionResult] = []

            // Detect animals
            let animalRequest = VNRecognizeAnimalsRequest { request, error in
                guard error == nil,
                      let observations = request.results as? [VNRecognizedObjectObservation] else {
                    return
                }

                for observation in observations {
                    let labels = observation.labels.map { $0.identifier }
                    let confidence = observation.labels.first?.confidence ?? 0.0

                    results.append(ObjectDetectionResult(
                        label: labels.joined(separator: ", "),
                        confidence: confidence,
                        boundingBox: observation.boundingBox
                    ))
                }
            }

            // Detect humans
            let humanRequest = VNDetectHumanRectanglesRequest { request, error in
                guard error == nil,
                      let observations = request.results as? [VNHumanObservation] else {
                    return
                }

                for observation in observations {
                    results.append(ObjectDetectionResult(
                        label: "person",
                        confidence: observation.confidence,
                        boundingBox: observation.boundingBox
                    ))
                }
            }

            // Perform requests
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([animalRequest, humanRequest])
            } catch {
                print("Vision request failed: \(error)")
            }

            continuation.resume(returning: results)
        }
    }

    // MARK: - Custom Model Detection

    /// Detect objects using custom Core ML model
    /// This method loads the model using the model class name configured in CoreMLModelConfig
    /// Add a Core ML model (.mlmodel) to the project and configure modelConfig to activate
    ///
    /// IMPORTANT: To use a custom model, you need to uncomment the appropriate section below
    /// and add the model instantiation code. This is necessary because Swift doesn't support
    /// dynamic instantiation of Core ML models without knowing the type at compile time.
    private func detectWithCustomModel(cgImage: CGImage, config: CoreMLModelConfig) async -> [ObjectDetectionResult] {
        return await withCheckedContinuation { continuation in
            var results: [ObjectDetectionResult] = []

            // Load model based on configuration
            // ACTIVATED: YOLOv8n model

            // FOR YOLOV8N MODEL:
            guard config.modelName == "yolov8n",
                  let model = try? yolov8n(configuration: MLModelConfiguration()),
                  let visionModel = try? VNCoreMLModel(for: model.model) else {
                print("❌ Failed to load yolov8n model")
                continuation.resume(returning: [])
                return
            }

            // Step 2: Perform detection

            let request = VNCoreMLRequest(model: visionModel) { request, error in
                if let error = error {
                    print("❌ Core ML request error: \(error.localizedDescription)")
                    return
                }

                guard let observations = request.results as? [VNRecognizedObjectObservation] else {
                    return
                }

                // Process detections
                for observation in observations where observation.confidence > config.confidenceThreshold {
                    // Skip if we've reached max detections
                    if results.count >= config.maxDetections {
                        break
                    }

                    // Extract label
                    let label = observation.labels.first?.identifier ?? "unknown"

                    // Extract attributes (color, type, etc.)
                    var attributes: [String: String] = [:]

                    // Extract color if enabled
                    if config.extractColors {
                        if let color = ColorExtractor.extractDominantColor(from: cgImage, boundingBox: observation.boundingBox) {
                            attributes["color"] = color
                        }
                    }

                    // Add type from secondary labels if available
                    if observation.labels.count > 1 {
                        let types = observation.labels.dropFirst().prefix(2).map { $0.identifier }
                        if !types.isEmpty {
                            attributes["type"] = types.joined(separator: ", ")
                        }
                    }

                    results.append(ObjectDetectionResult(
                        label: label,
                        confidence: observation.confidence,
                        boundingBox: observation.boundingBox,
                        attributes: attributes.isEmpty ? nil : attributes
                    ))
                }
            }

            request.imageCropAndScaleOption = .scaleFill

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
                print("✅ Core ML detection completed: \(results.count) objects found")
            } catch {
                print("❌ Core ML request failed: \(error.localizedDescription)")
            }

            continuation.resume(returning: results)
        }
    }

    // MARK: - Helper Methods

    /// Deduplicate detection results by removing overlapping detections
    /// Keeps the detection with higher confidence when bounding boxes overlap significantly
    private func deduplicateResults(_ results: [ObjectDetectionResult]) -> [ObjectDetectionResult] {
        var deduplicated: [ObjectDetectionResult] = []

        for result in results.sorted(by: { $0.confidence > $1.confidence }) {
            let hasOverlap = deduplicated.contains { existing in
                // Calculate intersection over union (IoU)
                let intersection = result.boundingBox.intersection(existing.boundingBox)
                if intersection.isEmpty { return false }

                let intersectionArea = intersection.width * intersection.height
                let union = result.boundingBox.union(existing.boundingBox)
                let unionArea = union.width * union.height

                let iou = intersectionArea / unionArea

                // If IoU > 0.5 and labels are similar, consider it a duplicate
                return iou > 0.5 && areLabelsSimilar(result.label, existing.label)
            }

            if !hasOverlap {
                deduplicated.append(result)
            }
        }

        return deduplicated
    }

    /// Check if two labels refer to the same or similar objects
    private func areLabelsSimilar(_ label1: String, _ label2: String) -> Bool {
        let normalized1 = label1.lowercased()
        let normalized2 = label2.lowercased()

        // Exact match
        if normalized1 == normalized2 { return true }

        // One contains the other
        if normalized1.contains(normalized2) || normalized2.contains(normalized1) {
            return true
        }

        // Common synonyms
        let synonyms: [[String]] = [
            ["person", "human", "man", "woman", "people"],
            ["dog", "puppy", "canine"],
            ["cat", "kitten", "feline"],
            ["car", "vehicle", "automobile"],
            ["phone", "mobile", "smartphone", "cellphone"]
        ]

        for group in synonyms {
            if group.contains(normalized1) && group.contains(normalized2) {
                return true
            }
        }

        return false
    }

    /// Convert bounding box to JSON string
    static func boundingBoxToJSON(_ box: CGRect) -> String {
        let dict: [String: Double] = [
            "x": Double(box.origin.x),
            "y": Double(box.origin.y),
            "width": Double(box.width),
            "height": Double(box.height)
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: dict),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return "{}"
        }

        return jsonString
    }
}
