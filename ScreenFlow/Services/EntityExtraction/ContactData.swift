//
//  ContactData.swift
//  ScreenFlow
//
//  Structure for holding extracted contact/business card information
//

import Foundation

/// Holds extracted contact information from business cards or contact screenshots
struct ContactData {
    var name: String?
    var company: String?
    var jobTitle: String?
    var phone: String?
    var email: String?
    var address: String?

    var isValid: Bool {
        // Must have a name and at least one contact method
        guard name != nil else { return false }
        return phone != nil || email != nil
    }

    var confidence: Double {
        var score = 0.0

        if name != nil { score += 0.3 }
        if phone != nil { score += 0.2 }
        if email != nil { score += 0.2 }
        if company != nil { score += 0.15 }
        if jobTitle != nil { score += 0.1 }
        if address != nil { score += 0.05 }

        return score
    }
}
