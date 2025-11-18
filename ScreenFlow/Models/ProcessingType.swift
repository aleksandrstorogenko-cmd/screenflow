//
//  ProcessingType.swift
//  ScreenFlow
//
//  Screenshot processing type options
//

import Foundation

/// Screenshot processing method
enum ProcessingType: String, CaseIterable, Identifiable {
    /// Simple and fast offline processing with OCR + Vision
    case offline = "offline"

    /// Apple Intelligence processing (iOS 26+)
    case appleIntelligence = "apple_intelligence"

    /// Online AI model processing
    case onlineAI = "online_ai"

    var id: String { rawValue }

    /// Display name for the processing type
    var displayName: String {
        switch self {
        case .offline:
            return "Standard"
        case .appleIntelligence:
            return "Smart"
        case .onlineAI:
            return "Smart+ AI"
        }
    }

    /// Description of the processing type
    var description: String {
        switch self {
        case .offline:
            return "Fast offline processing with OCR and object detection"
        case .appleIntelligence:
            return "Advanced on-device processing powered by Apple Intelligence"
        case .onlineAI:
            return "Premium cloud-based AI processing for best results"
        }
    }

    /// Check if this processing type is available on the current device
    var isAvailable: Bool {
        switch self {
        case .offline:
            return true
        case .appleIntelligence:
            if #available(iOS 26, *) {
                return true
            }
            return false
        case .onlineAI:
            return true // Will require network
        }
    }
}
