//
//  ContactActionHelper.swift
//  ScreenFlow
//
//  Helper for contact-related actions
//

import Foundation
import Contacts
import ContactsUI

/// Helper for creating and saving contacts from screenshots
/// TODO: Refactor to use ActionExecutor service instead of inline implementation
struct ContactActionHelper {

    /// Result of contact preparation
    enum Result {
        case success(contact: CNMutableContact)
        case failure(title: String, message: String)
    }

    /// Prepare a contact from extracted data
    static func prepareContact(from screenshot: Screenshot) -> Result {
        guard let extracted = screenshot.extractedData else {
            return .failure(title: "Cannot Save Contact", message: "No contact information found")
        }

        let contact = CNMutableContact()

        // Add name
        if let name = extracted.contactName {
            let components = name.components(separatedBy: " ")
            if components.count > 0 {
                contact.givenName = components[0]
            }
            if components.count > 1 {
                contact.familyName = components.dropFirst().joined(separator: " ")
            }
        }

        // Add phone numbers
        for phoneNumber in extracted.phoneNumbers {
            contact.phoneNumbers.append(CNLabeledValue(
                label: CNLabelPhoneNumberMain,
                value: CNPhoneNumber(stringValue: phoneNumber)
            ))
        }
        if let contactPhone = extracted.contactPhone {
            contact.phoneNumbers.append(CNLabeledValue(
                label: CNLabelPhoneNumberMain,
                value: CNPhoneNumber(stringValue: contactPhone)
            ))
        }

        // Add emails
        for email in extracted.emails {
            contact.emailAddresses.append(CNLabeledValue(
                label: CNLabelHome,
                value: email as NSString
            ))
        }
        if let contactEmail = extracted.contactEmail {
            contact.emailAddresses.append(CNLabeledValue(
                label: CNLabelWork,
                value: contactEmail as NSString
            ))
        }

        // Add company and job title
        if let company = extracted.contactCompany {
            contact.organizationName = company
        }
        if let jobTitle = extracted.contactJobTitle {
            contact.jobTitle = jobTitle
        }

        // Add address
        if let address = extracted.contactAddress {
            let postalAddress = CNMutablePostalAddress()
            postalAddress.street = address
            contact.postalAddresses.append(CNLabeledValue(
                label: CNLabelWork,
                value: postalAddress
            ))
        }

        return .success(contact: contact)
    }
}
