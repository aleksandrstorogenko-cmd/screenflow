//
//  CoreMLModelConfig.swift
//  ScreenFlow
//
//  Configuration for Core ML object detection models
//

import Foundation

/// Configuration for Core ML models
struct CoreMLModelConfig {
    /// Model name (as it appears in Xcode after adding .mlmodel file)
    let modelName: String

    /// Minimum confidence threshold for detections
    let confidenceThreshold: Float

    /// Whether to extract color attributes
    let extractColors: Bool

    /// Maximum number of detections to return
    let maxDetections: Int

    /// Whether the model is currently available
    var isAvailable: Bool {
        // Check if model class exists at runtime
        // This prevents crashes if model file is not added
        return NSClassFromString(modelName) != nil
    }

    // MARK: - Predefined Configurations

    /// YOLOv8n configuration - Fast and accurate
    static let yolov8n = CoreMLModelConfig(
        modelName: "yolov8n",
        confidenceThreshold: 0.3,
        extractColors: true,
        maxDetections: 20
    )

    /// MobileNetV3-SSD configuration - Balanced performance
    static let mobilenetv3 = CoreMLModelConfig(
        modelName: "MobileNetV3SSD",
        confidenceThreshold: 0.35,
        extractColors: true,
        maxDetections: 15
    )

    /// SqueezeNet configuration - Lightweight
    static let squeezenet = CoreMLModelConfig(
        modelName: "SqueezeNet",
        confidenceThreshold: 0.4,
        extractColors: false,
        maxDetections: 10
    )

    /// Custom model configuration
    /// Use this if you add a model with a different name
    static func custom(
        modelName: String,
        confidenceThreshold: Float = 0.3,
        extractColors: Bool = true,
        maxDetections: Int = 20
    ) -> CoreMLModelConfig {
        return CoreMLModelConfig(
            modelName: modelName,
            confidenceThreshold: confidenceThreshold,
            extractColors: extractColors,
            maxDetections: maxDetections
        )
    }
}
