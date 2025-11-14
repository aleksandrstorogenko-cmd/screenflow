//
//  ActionDataDecoder.swift
//  ScreenFlow
//
//  Utility for decoding action data from JSON strings
//

import Foundation

/// Decodes action data from JSON strings
struct ActionDataDecoder {
    /// Decode event data from JSON
    static func decodeEventData(_ jsonString: String) -> (name: String?, startDate: Date?, endDate: Date?, location: String?, description: String?)? {
        guard let data = jsonString.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        let name = dict["name"] as? String
        let startDate = (dict["startDate"] as? TimeInterval).map { Date(timeIntervalSince1970: $0) }
        let endDate = (dict["endDate"] as? TimeInterval).map { Date(timeIntervalSince1970: $0) }
        let location = dict["location"] as? String
        let description = dict["description"] as? String

        return (name, startDate, endDate, location, description)
    }

    /// Decode contact data from JSON
    static func decodeContactData(_ jsonString: String) -> (name: String?, company: String?, jobTitle: String?, phone: String?, email: String?, address: String?)? {
        guard let data = jsonString.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        let name = dict["name"] as? String
        let company = dict["company"] as? String
        let jobTitle = dict["jobTitle"] as? String
        let phone = dict["phone"] as? String
        let email = dict["email"] as? String
        let address = dict["address"] as? String

        return (name, company, jobTitle, phone, email, address)
    }

    /// Decode simple string value
    static func decodeString(_ jsonString: String) -> String? {
        guard let data = jsonString.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let value = dict["value"] as? String else {
            return nil
        }
        return value
    }

    /// Decode array of strings
    static func decodeStringArray(_ jsonString: String) -> [String]? {
        guard let data = jsonString.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let values = dict["values"] as? [String] else {
            return nil
        }
        return values
    }
}
