//
//  Array+SafeSubscript.swift
//  ScreenFlow
//
//  Extension providing safe array subscript access
//

import Foundation

/// Extension for safe array access
extension Array {
    /// Safe subscript that returns nil instead of crashing when index is out of bounds
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
