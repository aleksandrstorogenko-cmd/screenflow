//
//  ContactViewController.swift
//  ScreenFlow
//
//  SwiftUI wrapper for CNContactViewController
//

import SwiftUI
import Contacts
import ContactsUI

/// SwiftUI wrapper for CNContactViewController
struct ContactViewController: UIViewControllerRepresentable {
    let contact: CNMutableContact
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> UINavigationController {
        let contactVC = CNContactViewController(forNewContact: contact)
        contactVC.delegate = context.coordinator
        contactVC.contactStore = CNContactStore()

        let navController = UINavigationController(rootViewController: contactVC)
        return navController
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss)
    }

    class Coordinator: NSObject, CNContactViewControllerDelegate {
        let onDismiss: () -> Void

        init(onDismiss: @escaping () -> Void) {
            self.onDismiss = onDismiss
        }

        func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
            onDismiss()
        }
    }
}
