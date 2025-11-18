//
//  ContactInfoCard.swift
//  ScreenFlow
//
//  Card displaying extracted contact information
//

import SwiftUI

/// Card showing contact/business card details
struct ContactInfoCard: View {
    let data: ExtractedData

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "person.crop.circle")
                    .foregroundColor(.blue)
                Text("Contact")
                    .font(.headline)
            }

            // Contact details
            if let name = data.contactName {
                DetailRow(icon: "person", label: "Name", value: name)
            }

            if let company = data.contactCompany {
                DetailRow(icon: "building.2", label: "Company", value: company)
            }

            if let jobTitle = data.contactJobTitle {
                DetailRow(icon: "briefcase", label: "Job Title", value: jobTitle)
            }

            if let phone = data.contactPhone {
                DetailRow(icon: "phone", label: "Phone", value: phone)
            }

            if let email = data.contactEmail {
                DetailRow(icon: "envelope", label: "Email", value: email)
            }

            if let address = data.contactAddress {
                DetailRow(icon: "location", label: "Address", value: address)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(26)
        .padding(.horizontal)
    }
}
