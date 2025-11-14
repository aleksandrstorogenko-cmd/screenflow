//
//  ActionDataEncoder.swift
//  ScreenFlow
//
//  Utility for encoding action-specific data as JSON
//

import Foundation

/// Encodes action data to JSON strings
struct ActionDataEncoder {
    /// Encode event data to JSON
    static func encodeEventData(
        name: String?,
        startDate: Date?,
        endDate: Date?,
        location: String?,
        description: String?
    ) -> String {
        var dict: [String: Any] = [:]

        if let name = name { dict["name"] = name }
        if let startDate = startDate { dict["startDate"] = startDate.timeIntervalSince1970 }
        if let endDate = endDate { dict["endDate"] = endDate.timeIntervalSince1970 }
        if let location = location { dict["location"] = location }
        if let description = description { dict["description"] = description }

        return encode(dict)
    }

    /// Encode contact data to JSON
    static func encodeContactData(
        name: String?,
        company: String?,
        jobTitle: String?,
        phone: String?,
        email: String?,
        address: String?
    ) -> String {
        var dict: [String: Any] = [:]

        if let name = name { dict["name"] = name }
        if let company = company { dict["company"] = company }
        if let jobTitle = jobTitle { dict["jobTitle"] = jobTitle }
        if let phone = phone { dict["phone"] = phone }
        if let email = email { dict["email"] = email }
        if let address = address { dict["address"] = address }

        return encode(dict)
    }

    /// Encode simple string value
    static func encodeString(_ value: String) -> String {
        return encode(["value": value])
    }

    /// Encode array of strings
    static func encodeStringArray(_ values: [String]) -> String {
        return encode(["values": values])
    }

    // MARK: - Private Helpers

    private static func encode(_ dictionary: [String: Any]) -> String {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: dictionary, options: []),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return "{}"
        }
        return jsonString
    }
}
