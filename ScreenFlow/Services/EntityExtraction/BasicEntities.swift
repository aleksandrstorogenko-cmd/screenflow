//
//  BasicEntities.swift
//  ScreenFlow
//
//  Structure for holding basic extracted entities
//

import Foundation

/// Holds basic entities extracted from text using NSDataDetector
struct BasicEntities {
    var urls: [URL] = []
    var emails: [String] = []
    var phoneNumbers: [String] = []
    var addresses: [String] = []
    var dates: [Date] = []

    var hasAnyEntity: Bool {
        !urls.isEmpty || !emails.isEmpty || !phoneNumbers.isEmpty || !addresses.isEmpty || !dates.isEmpty
    }
}
