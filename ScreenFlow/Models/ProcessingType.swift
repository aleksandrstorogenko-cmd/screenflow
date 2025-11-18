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
            return "OCR + Vision"
        case .appleIntelligence:
            return "Apple Intelligence"
        case .onlineAI:
            return "Online AI"
        }
    }

    /// Description of the processing type
    var description: String {
        switch self {
        case .offline:
            return "Simple and fast offline processing"
        case .appleIntelligence:
            return "Effective processing with Apple Intelligence (iOS 26+)"
        case .onlineAI:
            return "Online processing with AI model"
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
