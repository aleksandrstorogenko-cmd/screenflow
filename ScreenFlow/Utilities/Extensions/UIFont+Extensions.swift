//
//  UIFont+Extensions.swift
//  ScreenFlow
//
//  UIFont utility extensions
//

import UIKit
import SwiftUI

extension UIFont {
    /// Returns an italic version of the font
    func italic() -> UIFont {
        let descriptor = fontDescriptor.withSymbolicTraits(.traitItalic)
        return UIFont(descriptor: descriptor ?? fontDescriptor, size: pointSize)
    }

    /// Returns a bold version of the font
    func bold() -> UIFont {
        let descriptor = fontDescriptor.withSymbolicTraits(.traitBold)
        return UIFont(descriptor: descriptor ?? fontDescriptor, size: pointSize)
    }

    /// Returns a bold italic version of the font
    func boldItalic() -> UIFont {
        let descriptor = fontDescriptor.withSymbolicTraits([.traitBold, .traitItalic])
        return UIFont(descriptor: descriptor ?? fontDescriptor, size: pointSize)
    }
}

extension Font.Weight {
    /// Convert SwiftUI Font.Weight to UIFont.Weight
    var uiFontWeight: UIFont.Weight {
        switch self {
        case .ultraLight: return .ultraLight
        case .thin: return .thin
        case .light: return .light
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        case .heavy: return .heavy
        case .black: return .black
        default: return .regular
        }
    }
}
