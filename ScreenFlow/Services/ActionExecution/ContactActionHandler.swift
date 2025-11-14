//
//  ContactActionHandler.swift
//  ScreenFlow
//
//  Handles contact actions using Contacts framework
//

import Foundation
import Contacts
import ContactsUI
import UIKit

/// Handles add-to-contacts actions
@MainActor
final class ContactActionHandler: NSObject {
    private let contactStore = CNContactStore()

    /// Execute contact action
    func execute(_ action: SmartAction) async -> Bool {
        // Request contacts access
        let granted = await requestContactsAccess()
        guard granted else {
            print("Contacts access denied")
            return false
        }

        // Decode contact data
        guard let contactData = ActionDataDecoder.decodeContactData(action.actionData) else {
            print("Failed to decode contact data")
            return false
        }

        // Create contact
        let contact = CNMutableContact()

        // Set name
        if let fullName = contactData.name {
            let components = fullName.components(separatedBy: " ")
            if components.count >= 2 {
                contact.givenName = components.first ?? ""
                contact.familyName = components.dropFirst().joined(separator: " ")
            } else {
                contact.givenName = fullName
            }
        }

        // Set organization
        if let company = contactData.company {
            contact.organizationName = company
        }

        // Set job title
        if let jobTitle = contactData.jobTitle {
            contact.jobTitle = jobTitle
        }

        // Set phone
        if let phone = contactData.phone {
            let phoneNumber = CNLabeledValue(
                label: CNLabelWork,
                value: CNPhoneNumber(stringValue: phone)
            )
            contact.phoneNumbers = [phoneNumber]
        }

        // Set email
        if let email = contactData.email {
            let emailValue = CNLabeledValue(
                label: CNLabelWork,
                value: email as NSString
            )
            contact.emailAddresses = [emailValue]
        }

        // Set address
        if let address = contactData.address {
            let postalAddress = CNMutablePostalAddress()
            postalAddress.street = address
            let addressValue = CNLabeledValue(
                label: CNLabelWork,
                value: postalAddress as CNPostalAddress
            )
            contact.postalAddresses = [addressValue]
        }

        return presentContactForm(with: contact)
    }

    // MARK: - Private Helpers

    private func presentContactForm(with contact: CNMutableContact) -> Bool {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("Failed to get root view controller for contact form")
            return false
        }

        let contactVC = CNContactViewController(forNewContact: contact)
        contactVC.delegate = self
        contactVC.contactStore = contactStore

        let navController = UINavigationController(rootViewController: contactVC)

        var topController = rootViewController
        while let presented = topController.presentedViewController {
            topController = presented
        }

        topController.present(navController, animated: true)
        print("Presented contact form for: \(contact.givenName) \(contact.familyName)")
        return true
    }

    private func requestContactsAccess() async -> Bool {
        return await withCheckedContinuation { continuation in
            contactStore.requestAccess(for: .contacts) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }
}

// MARK: - CNContactViewControllerDelegate

extension ContactActionHandler: CNContactViewControllerDelegate {
    func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
        viewController.dismiss(animated: true)
    }
}
