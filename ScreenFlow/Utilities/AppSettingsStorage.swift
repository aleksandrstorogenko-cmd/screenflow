//
//  AppSettingsStorage.swift
//  ScreenFlow
//
//  Centralized access to UserDefaults-stored app settings
//

import SwiftUI

/// Provides strongly-typed accessors for app-level settings stored with AppStorage.
@propertyWrapper
struct AppSettingsStorage: DynamicProperty {
    /// Stored flag for using AI-enhanced processing
    @AppStorage(StorageKey.useAIProcessing.rawValue)
    private var useAIProcessingValue: Bool = false

    var wrappedValue: Accessor {
        Accessor(useAIProcessingValue: $useAIProcessingValue)
    }

    /// Internal accessor that exposes convenience bindings and helpers.
    struct Accessor {
        fileprivate var useAIProcessingValue: Binding<Bool>

        /// Flag that indicates whether AI features are enabled
        var useAIProcessing: Bool {
            get { useAIProcessingValue.wrappedValue }
            nonmutating set { useAIProcessingValue.wrappedValue = newValue }
        }

        /// Binding for the AI processing flag
        var useAIProcessingBinding: Binding<Bool> {
            useAIProcessingValue
        }
    }

    /// All keys used for AppStorage-backed values
    private enum StorageKey: String {
        case useAIProcessing = "useAIProcessing"
    }
}
